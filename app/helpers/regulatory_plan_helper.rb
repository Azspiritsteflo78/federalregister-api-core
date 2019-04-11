module RegulatoryPlanHelper
  def fuzzy_date_formatter(date)
    case date
    when nil
      nil
    when /\d{4}-\d{2}-00/
      Date.parse(date.next).to_s(:month_year)
    when /\d{4}-\d{2}-\d{2}/
      Date.parse(date).to_s(:short_ordinal)
    else
      date
    end
  end

  def format_regulation_text(text)
    add_citation_links(simple_format(auto_link(text.strip, :href_options => { :class => 'external' })))
  end

  def issue_season(plan)
    (year, season) = plan.issue.match(/(\d{4})(\d{2})/)[1,2]

    "#{season == '04' ? 'Spring' : 'Fall'} #{year}"
  end
end