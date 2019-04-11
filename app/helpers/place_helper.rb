module PlaceHelper
  def entry_list(place)
    list = []
    list << '<ul>'
    place.entries.each do |entry|
      #TODO: HELP-DESIGN perhaps add a class rather than style inline
      list << "<li style=\"padding-top:5px;\">#{link_to(truncate_words(entry.title, :length => 80), entry_path(entry) )}</li>"
    end
    list << '</ul>'
    list.join(" ")
  end
end