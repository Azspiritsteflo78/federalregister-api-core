module EntryHelper
  def display_agencies_for_entries(entry)
    agencies = []
    unless entry.agency_id.nil? || entry.agency.parent_id.nil?
      agencies << link_to(entry.agency.parent.name, agency_path(entry.agency.parent) )
    end
    agencies << link_to(entry.agency.name, agency_path(entry.agency) )
    agencies.join(' :: ')
  end
end