class Event < ApplicationModel
  include Icalendar
  PUBLIC_MEETING_PHRASES = ["public meeting", "public hearing", "town hall meeting", "web dialogue", "webinar"]

  EVENT_TYPES_SINGULAR = {
    'PublicMeeting' => 'Public Meeting',
    'ClosedMeeting' => 'Closed Meeting',
    'CommentsOpen'  => 'Comment Period Opening',
    'CommentsClose' => 'Comment Period Closing',
    'EffectiveDate' => 'Effective Date',
    'RegulationsDotGovCommentsClose' => "Regulations.gov Comment Period Closing",
  }
  EVENT_TYPES_PLURAL = {
    'PublicMeeting' => 'Public Meetings',
    'ClosedMeeting' => 'Closed Meetings',
    'CommentsOpen'  => 'Comment Periods Opening',
    'CommentsClose' => 'Comment Periods Closing',
    'RegulationsDotGovCommentsClose' => "Regulations.gov Comment Periods Closing",
    'EffectiveDate' => 'Effective Dates'
  }

  belongs_to :entry
  belongs_to :place
  has_many :agency_assignments, :through => :entry, :foreign_key => "entries.id"
  validates_presence_of :date, :event_type
  validates_presence_of :title, :if => Proc.new{|e| e.event_type == 'PublicMeeting' || e.event_type == 'ClosedMeeting'}
  validates_inclusion_of :event_type, :in => EVENT_TYPES_SINGULAR.keys

  def self.public_meeting
    scoped(:conditions => {:event_type => "PublicMeeting"})
  end

  def agencies
    agency_assignments.map(:agency)
  end

  def type
    ::Event::EVENT_TYPES_SINGULAR[event_type]
  end

  def title
    self['title'] || entry.title
  end

  def entry_full_text
    entry.raw_text
  end

  def to_ics
    ical_event = Icalendar::Event.new
    ical_event.start = self.date
    ical_event.end = self.date
    ical_event.summary = "#{self.type}: #{self.title}"
    ical_event.unique_id = "https://www.federalregister.gov/events/#{self.id}"
    ical_event.description = self.entry.try(:abstract)
    ical_event
  end

  define_index do
    # fields
    indexes "entries.title", :as => :title
    indexes entry.abstract
    indexes place.name, :as => :place
    indexes event_type, :as => :type, :facet => true
    indexes "CONCAT('#{entries.document_path}/full_text/raw/', entries.document_file_path, '.txt')", :as => :entry_full_text, :file => true

    # attributes
    has date
    has entry.agency_assignments(:agency_id), :as => :agency_ids
    has place_id

    set_property :field_weights => {
      "title" => 100,
      "place" => 50,
      "abstract" => 50,
      "full_text" => 25,
    }
    where "events.date BETWEEN DATE_SUB(NOW(), INTERVAL 1 MONTH) AND DATE_ADD(NOW(), INTERVAL 2 YEAR) AND event_type != 'RegulationsDotGovCommentsCloseDate'"
    set_property :delta => ThinkingSphinx::Deltas::ManualDelta
  end
  # this line must appear after the define_index block
  include ThinkingSphinx::Deltas::ManualDelta::ActiveRecord

end
