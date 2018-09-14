# encoding: utf-8
# == Schema Information
#
# Table name: events
#
#  id                  :integer          not null, primary key
#  title               :string(255)
#  category            :string(255)
#  starts_at           :datetime
#  ends_at             :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  current_state       :string(255)
#  description         :text
#  legacy_identifier   :integer
#  timezone            :string(255)
#  created_by_id       :integer
#  hosted              :boolean
#  rules               :text
#  setup_completed_at  :datetime
#  setup_skipped_by_id :integer
#  headline            :text
#  eb_uid              :string(255)
#  email_on_publish    :boolean
#  private_event       :boolean
#  import_eb_attendees :boolean
#  public_event        :boolean          default(TRUE)
#  search_vector       :tsvector
#  users_count         :integer          default(0), not null
#  sponsors_count      :integer          default(0), not null
#  projects_count      :integer          default(0), not null
#  hacker_rank_enabled :boolean
#  featured_at         :datetime
#  meetup_uid          :string(255)
#  hashtag             :string(255)
#  submission_deadline :datetime
#

class Event < ActiveRecord::Base
  include AASM
  include Events::Associations
  include Events::EbriteMethods
  include Profiles::ModelAttributes

  DEFAULT_DATE_FORMAT = "%b %d %Y"
  DEFAULT_TIME_FORMAT = "%I:%M %p"
  FILTERS = :time, :location, :term, :page, :per_page, :past

  is_impressionable

  scope :hosted, where(:hosted => 't')

  scope :past, -> do
    where("events.starts_at < ?", Time.zone.now).order('starts_at desc')
  end

  scope :upcoming, -> do
    where("events.ends_at >= ?", Time.zone.now)
  end

  scope :this_week, -> do
    starts = Time.zone.now.beginning_of_week
    ends = starts + 1.week
    where(:starts_at => starts..ends)
  end

  scope :next_30_days, -> do
    starts = Time.zone.now
    ends = starts + 30.days
    where(:starts_at => starts..ends)
  end

  scope :next_90_days, -> do
    starts = Time.zone.now.beginning_of_day
    ends = starts + 90.days
    where(:starts_at => starts..ends)
  end

  scope :public_events, -> do
    where(:public_event => 't', :current_state => 'published')
  end

  scope :featured, -> do
    public_events.where("events.featured_at IS NOT NULL")
  end

  scope :near, ->(location, radius = 100) do
    location_ids = Location.near(location, radius).where(:locatable_type => "Event").pluck(:id)
    joins(:location).where(:locations => { :id => location_ids })
  end

  scope :with_projects, where('events.projects_count > 0')

  search_methods :api_eq # tells meta_search to use this method as a filter
  search_methods :country_eq
  search_methods :region_eq

  attr_accessor :start_date_text , :start_time_text , :starts_at_text ,
                :end_date_text   , :end_time_text   , :ends_at_text, :location_text,
                :submission_date_text , :submission_time_text , :submission_deadline_text

  attr_accessible :title, :location_text, :description, :featured, :starts_at,
                  :ends_at, :start_date_text, :start_time_text, :end_date_text,
                  :end_time_text, :submission_deadline, :submission_date_text ,
                  :submission_time_text , :timezone, :eb_uid, :email_on_publish, :public_event,
                  :current_state, :headline, :rules, :location_attributes, :import_eb_attendees,
                  :hacker_rank_enabled, :featured_at, :meetup_uid, :hashtag, :private_event

  validates_presence_of :title, :timezone, :start_date_text, :submission_date_text

  before_validation do
    ensure_timezone
    save_starts_at
    save_submission_deadline
    save_ends_at
    ensure_ends_at
  end

  before_save do
    save_location
    geocode_location
    ensure_hosted_flag
    trim_hashtag
    unless wiki
      build_wiki
    end
  end

  before_create :create_schedule_for_each_day

  # Initial state is draft
  aasm column: :current_state do
    state :draft, :initial => true
    state :published
    event :publish, :after => :invite_attendees_after_published do
      transitions :from => :draft, :to => :published
    end
    event :unpublish do
      transitions :from => :published, :to   => :draft
    end
  end

  def self.default_json_attrs
   {
     only:    [ :id,
                :current_state,
                :title,
                :rules,
                :starts_at,
                :ends_at,
                :submission_deadline,
                :description,
                :created_at,
                :updated_at ],
     methods: [ :image,
                :url ],
     include: [ :location ]
    }
  end


  def self.filter(filters = {})
    events = Event.public_events

    if filters[:location].present?
      events = events.near(filters[:location])
    end

    case filters[:time]
    when "this_week"
      events = events.this_week
    when "next_30_days"
      events = events.next_30_days
    when "next_90_days"
      events = events.next_90_days
    when "past"
      events = events.past
    else
      events = events.upcoming
    end

    if filters[:term].present?
      events = events.search(filters[:term])
    end

    events = events.order("events.starts_at")
    filters[:page] ||= 1
    filters[:per_page] ||= 20
    events.paginate(filters.slice(:page, :per_page))
  end

  def self.search(query)
    query = "*" if query.blank?
    query  = query.gsub(/\s/,"+") + ":*"
    squery = sanitize_sql_array [ "to_tsquery('english', ?)", query ]
    conditions = "events.search_vector @@ #{squery} "
    order = "ts_rank_cd(events.search_vector, #{squery}) DESC"
    Event.where(conditions).order(order)
  end

  def create_default_judging_criteria
    criteria = %w[Creativity Design Impactfulness Simplicity]
    event_judging_criteria.create(criteria.map {|c| {title: c} })
  end

  def trim_hashtag
    unless self.hashtag.nil?
      if self.hashtag.starts_with?('#')
        self.hashtag = hashtag[1..-1]
      end
    end
  end

  def self.featured_events(limit = 3)
    Event.featured.order('events.featured_at desc').limit(limit).includes(:profile, :location)
  end

  def self.filter_old(filters={})
    results = Event.unscoped
    opts = { ends_from: Time.zone.now, ends_to: nil, location: nil }.merge(filters)
    if opts[:location].present?
      location_ids = Location.near(opts[:location], 50, :order => :distance).pluck(:id)
      results = results.joins(:location).where(:locations => {:id => location_ids})
    end
    if opts[:starts_from].present?
      results = results.where("ends_at >= ?", opts[:ends_from])
    end
    if opts[:ends_to].present?
      results = results.where("ends_at <= ?", opts[:ends_to])
    end
    results
  end

  def feature!
    update_attributes(:featured_at => Time.zone.now)
  end

  def featured?
    !!(featured_at)
  end

  # @return true if the event is claimed
  def claimed?
    hosted?
  end

  def live?
    if starts_at.present? && ends_at.present?
      starts_at <= Time.zone.now && ends_at >= Time.zone.now
    else
      false
    end
  end

  def start_date_text
    @start_date_text ||= starts_at.try(:in_time_zone, timezone).try(:strftime,DEFAULT_DATE_FORMAT)
  end

  def end_date_text
    @end_date_text ||= ends_at.try(:in_time_zone,timezone).try(:strftime,DEFAULT_DATE_FORMAT)
  end

  def submission_date_text
    @submission_date_text ||= submission_deadline.try(:in_time_zone,timezone).try(:strftime,DEFAULT_DATE_FORMAT)
  end

  def start_time_text
    unless @start_time_text.present?
      @start_time_text = starts_at.try(:in_time_zone,timezone).try(:strftime, DEFAULT_TIME_FORMAT)
    end
    @start_time_text
  end

  def end_time_text
    unless @end_time_text.present?
      @end_time_text = ends_at.try(:in_time_zone,timezone).try(:strftime, DEFAULT_TIME_FORMAT)
    end
    @end_time_text
  end

  def submission_time_text
    unless @submission_time_text.present?
      @submission_time_text = submission_deadline.try(:in_time_zone,timezone).try(:strftime, DEFAULT_TIME_FORMAT)
    end
    @submission_time_text
  end

  def save_location
    unless location.present?
      self.build_location
      self.location.location_text = @location_text
    end
  end

  def as_json(options = {})
    options = Event.default_json_attrs.merge(options)
    super
  end

  def json_attrs
    Event.default_json_attrs
  end

  def administrators
    User.joins(:event_users).where(:event_users => {:can_manage => 't'})
  end

  def judges
    self.event_users.where(:can_judge => 't')
  end

  # finds upcoming location near a location
  # or returns featured events
  def self.find_upcoming(opts = {})
    events = Event.public_events.upcoming
    location = opts[:location]
    if location.present?
      events = events.near(location)
    end
    events.order("starts_at asc")
  end

  def total_platforms
    result = []
    projects.each do |p|
      result.concat(p.platforms)
    end
    
    result.uniq
  end
  
  def projects_used(platform)
    project_ids = projects.all.collect(&:id)
    ids = ProjectPlatform.where("platform_id = ? and project_id in (?)", platform.id, project_ids).collect(&:project_id)

    Project.find(ids)
  end
  
  def report
    column_names = ["API", "Projects", "Total Projects"]
    CSV.generate do |csv|
      csv << column_names
      
      total_platforms.each do |platform|
        projects = projects_used(platform)
        
        csv << [platform.title, projects.collect(&:title).join(', '), projects.count]
      end
    end
  end
  
  def report_for_sponsor(sponsor)
    column_names = ["API", "#{slug.titleize}-Projects", "#{slug.titleize}-Projects-Count", "Projects", "Projects-Count"]
    CSV.generate do |csv|
      csv << ["API Analytics"]
      csv << column_names
      
      sponsor.platforms.each do |platform|
        projects = projects_used(platform)
        
        csv << [platform.title, projects.collect(&:title).join(', '), projects.count, platform.projects.collect(&:title).join(', '), platform.projects.count]
      end
      
      if won_prizes.present?
        csv << []
        csv << ["Projects won prizes"]
        csv << ["Prize", "Project won"]
        
        won_prizes.each do |prize|
          csv << [prize.title, prize.winning_project.title]
        end
      end
    end
  end
  
  def sponsored_members
    members = []
    e.sponsors.each do |sponsor|
      members.concat(sponsor.members)
    end
  end
  
  def won_prizes
    result = []
    prizes.each do |prize|
      result << prize if prize.winning_project.present?
    end
    result
  end
  
  def self.all_csv
    column_names = ["Event Title", "Evnet slug", "API", "Projects", "Total Projects"]
    CSV.generate do |csv|
      csv << column_names
      
      Event.all.each do |event|
        event.total_platforms.each do |platform|
          projects = event.projects_used(platform)
        
          csv << [event.title, event.slug, platform.title, projects.collect(&:title).join(', '), projects.count]
        end
      end
    end
  end

  def self.api_eq(platform_id)
    platform = Platform.find(platform_id)
    events = []
    platform.projects.each do |project|
      events.concat(project.events)
    end
    
    Event.where("id in (?)", events.collect(&:id))
  end

  def self.country_eq(country)
    Event.includes(:location).where("locations.country = ?", country)
  end

  def self.region_eq(region)
    Event.includes(:location).where("locations.region = ?", region)
  end

  
protected

  def create_schedule_for_each_day
    if starts_at.present? && ends_at.present?
      times = []
      # figure out dates
      (starts_at.to_date..ends_at.to_date).each do |date|
        self.schedules.build :day => date.to_time
      end
    end
  end

  # set the hosted flag to true
  def ensure_hosted_flag
    self.hosted ||= (administrators.count > 0)
    true
  end

  def geocode_location
    location.geocode if location.present?
  end

  def ensure_timezone
    self.timezone ||= 'UTC'
  end

  def ensure_ends_at
    if ends_at.blank? && starts_at.present?
      self.ends_at = starts_at + 24.hours
    end
  end

  def save_starts_at
    if @start_date_text.present?
      @start_time_text ||= "00:00"
      Time.zone = timezone
      Chronic.time_class = Time.zone
      unless self.starts_at = Chronic.parse("#{@start_date_text} #{@start_time_text}")
        errors.add :starts_at_text, "cannot be parsed"
      end
    end
  rescue ArgumentError
    errors.add :starts_at_text, "is out of range"
  end

  def save_ends_at
    if @end_date_text.present?
      @end_time_text ||= "00:00"
      Time.zone = timezone
      Chronic.time_class = Time.zone
      unless self.ends_at = Chronic.parse("#{@end_date_text} #{@end_time_text}")
        errors.add :ends_at_text, "cannot be parsed"
      end
    end
  rescue ArgumentError
    errors.add :ends_at_text, "is out of range"
  end

  def save_submission_deadline
    if @submission_date_text.present?
      @submission_time_text ||= "00:00"
      Time.zone = timezone
      Chronic.time_class = Time.zone
      unless self.submission_deadline = Chronic.parse("#{@submission_date_text} #{@submission_time_text}")
        errors.add :submission_deadline_text, "cannot be parsed"
      end
    end
  rescue ArgumentError
    errors.add :submission_deadline_text, "is out of range"
  end
end
