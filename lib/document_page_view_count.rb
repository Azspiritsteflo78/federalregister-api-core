class DocumentPageViewCount
  extend Memoist
  include CacheUtils

  PER_PAGE = 10000

  HISTORICAL_SET = "doc_counts:historical"
  TEMP_SET = "doc_counts:in_progress"
  TODAY_SET = "doc_counts:today"
  YESTERDAY_SET = "doc_counts:yesterday"

  def self.count_for(document_number)
    $redis.pipelined do
      $redis.zscore HISTORICAL_SET, document_number
      $redis.zscore YESTERDAY_SET, document_number
      $redis.zscore TODAY_SET, document_number
    end.compact.map{|count| count.to_i}.sum
  end

  def self.last_updated
    $redis.get "doc_counts:current_as_of"
  end

  def update_all(start_year=2010, end_year=Date.current.year, reset_counts=true)
    if reset_counts
      $redis.del(HISTORICAL_SET)
      $redis.del(YESTERDAY_SET)
    end

    $redis.del(TEMP_SET)
    $redis.del(TODAY_SET)

    # work through counts one year at a time
    # so as to keep requests reasonable (otherwise risk 503s -
    # heavy lift on the GA side to calculate these counts)
    (start_year..end_year).to_a.each do |year|
      start_date = Date.new(year,1,1)
      end_date = start_date.end_of_year

      # don't include today (it has it's own calculation)
      end_date = end_date - 1.day if year == Date.current.year

      update_counts(start_date, end_date, HISTORICAL_SET)
    end

    # update today's counts
    update_counts(Date.current, Date.current, TODAY_SET)

    clear_cache
  end

  def update_counts_for_today


    if Time.current.hour == 0
      # this is run once every 2 hours to update the current days counts
      # as such at midnight we want to finish calculating yesterdays count
      # and then move those counts into yesterdays counts
      update_counts(Date.current-1.day, Date.current-1.day, TODAY_SET)
      move_today_to_yesterday
    elsif Time.current.hour == 6
      # at 6 am we finalize yesterdays counts (GA applies post processing, etc)
      # and then merge those into the historical counts
      update_counts(Date.current-1.day, Date.current-1.day, YESTERDAY_SET)
      collapse_counts
    else
      update_counts(Date.current, Date.current, TODAY_SET)
    end

    clear_cache
  end

  def clear_cache
    purge_cache('/api/v1/documents')
    purge_cache('/documents/')
  end

  def update_counts(start_date, end_date, set)
    current_time = Time.current
    processed_results = 0

    log("processing: {start_date: #{start_date}, end_date: #{end_date}}")
    log("#{total_results(start_date, end_date)} results need processing")

    # work through counts in batches of PER_PAGE
    while processed_results < total_results(start_date, end_date) do
      log("processed_results: #{processed_results}/#{total_results(start_date, end_date)}")

      # get counts
      response = page_views(
        start_date: start_date,
        end_date: end_date,
        per_page: PER_PAGE,
        page_token: processed_results
      )

      results = response["reports"].first["data"]["rows"]

      # increment our counts hash in redis
      $redis.pipelined do
        counts_by_document_number(results) do |document_number, visits|
          $redis.zincrby(TEMP_SET, visits, document_number)
        end
      end

      # increment our processed results count
      processed_results += PER_PAGE
    end

    if total_results(start_date, end_date) > 0
      if set == TODAY_SET
        # store a copy of the set each hour for internal analysis
        $redis.zunionstore("doc_counts:#{Date.current.to_s(:iso)}:#{Time.current.hour}", [TEMP_SET])
        $redis.rename(TEMP_SET, set)
      else
        $redis.zunionstore(HISTORICAL_SET, [TEMP_SET, HISTORICAL_SET])
        $redis.del(TEMP_SET)
      end
    end

    $redis.set "doc_counts:current_as_of", current_time
  end

  def move_today_to_yesterday
    $redis.rename(TODAY_SET, YESTERDAY_SET)
    $redis.del(TODAY_SET)
  end

  def collapse_counts
    $redis.zunionstore(HISTORICAL_SET, [YESTERDAY_SET, HISTORICAL_SET])
    $redis.del(YESTERDAY_SET)
  end

  private

  def log(msg)
    logger.info("[#{Time.current}] #{msg}")
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/google_analytics_api.log")
  end

  # convert the GA response data structure into document_number, count
  def counts_by_document_number(rows)
    rows.each do |row|
      url = row["dimensions"][0]
      count = row["metrics"][0]["values"][0].to_i

      # ignore aggregate dimensions like "(other)"
      # and extract document_number
      document_number = url =~ /^\/(articles|documents)\// ? url.split('/')[5] : nil

      # only record page view data if we have a valid looking document number
      # (e.g. with a '-' in it)
      if document_number && document_number.include?('-')
        yield document_number, count
      end
    end
  end

  def total_results(start_date, end_date)
    page_views(
      page_size: 1,
      start_date: start_date,
      end_date: end_date
    )["reports"].first["data"]["rowCount"].to_i
  end
  memoize :total_results


  def page_views(args={})
    GoogleAnalytics::PageViews.new.counts(
      default_args.merge(args)
    )
  end

  def default_args
    {
      dimension_filters: dimension_filters,
    }
  end

  def dimension_filters
    [
      {
        filters: [
          {
            dimensionName: "ga:pagePath",
            operator: "REGEXP",
            expressions: ["^/(documents/|articles/)"]
          }
        ]
      }
    ]
  end
end
