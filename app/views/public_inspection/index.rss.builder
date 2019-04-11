xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    documents ||= []

    xml.title       feed_name
    xml.link        feed_url
    xml.pubDate     CGI.rfc1123_date documents.first.publication_date.to_time if documents.size > 0
    xml.description feed_description

    documents.each do |document|
      xml.item do
        if document.title.present?
          xml.title   document.title
        else
          xml.title   "#{[document.subject_1, document.subject_2, document.subject_3].compact.join(' ')}"
        end

        xml.link        entry_url(document)

        description = []
        description += document.docket_numbers.map(&:number)
        description << "Editorial note: #{document.editorial_note}" if document.editorial_note
        description << "FR DOC #: #{document.document_number}" if document.document_number
        description << "Publication Date: #{document.publication_date}" if document.publication_date
        description << number_to_human_size(document.pdf_file_size)
        description << pluralize(document.num_pages, 'page')

        xml.description h(description.join('; '))
        if document.filed_at
          xml.pubDate     CGI.rfc1123_date document.filed_at
        end
        xml.guid        entry_url(document)
        xml.dc :creator, document.agencies.map(&:name).to_sentence
      end
    end
  end
end
