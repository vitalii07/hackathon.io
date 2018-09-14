# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  email                   :string(255)
#  crypted_password        :string(255)
#  salt                    :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  legacy_identifier       :integer
#  legacy_crypted_password :string(255)
#  full_name               :string(255)
#  migrated_at             :datetime
#  forgot_password_code    :string(255)
#  eventbrite_token        :string(255)
#  eventbrite_uid          :string(255)
#  temp_email              :string(255)
#  confirm_email_code      :string(255)
#  confirm_email_status    :integer          default(0)
#  bio                     :text
#  current_state           :string(255)
#  invited_by_id           :integer
#  invitation_sent_at      :datetime
#  added_by_id             :integer
#  added_at                :datetime
#  signed_up_at            :datetime
#  mobile_phone            :string(255)
#  mobile_phone_2          :string(255)
#  headline                :text
#  setup_skipped_at        :datetime
#  hireable                :boolean
#  legacy_migrated_at      :datetime
#  setup_completed_at      :datetime
#  search_vector           :tsvector
#  hireable_for_project    :boolean
#  remember_token          :string(255)
#  featured                :boolean          default(FALSE)
#  featured_at             :datetime
#  likes_count             :integer
#

# Implemented as <b>State Machine</a>.
class User < ActiveRecord::Base
  include AASM
  include Auth::Model
  include Renderers::Markdown
  include Users::UserRelations
  include Profiles::ModelAttributes

  is_impressionable

  scope :featured, -> do
    where("users.featured_at IS NOT NULL")
  end

  scope :involved_in, ->(projects) { includes(:projects).merge(projects.scoped) }
  scope :worked_with, ->(user) { involved_in(user.projects).where(arel_table[:id].not_eq(user.id)) }

  search_methods :location_contains, :stack_eq, :role_in

  FILTERS = [ :locations, :event_ids, :platform_ids, :term, :page, :per_page, :hireable_for_project, :role_ids ]

  attr_accessor   :old_password, :photo_from_url

  alias_attribute :name,  :full_name
  alias_attribute :title, :full_name
  alias_attribute :intro, :headline

  aasm column: :current_state do
    state :new, initial: true
    state :invited  # user is invited by another user
    state :active   # only active users are allowed to login
    event :signup do
      transitions to: :active, from: [:new, :invited, :verified]
    end
  end

  attr_accessible :username,
                  :email,
                  :password,
                  :current_state,
                  :full_name,
                  :old_password,
                  :location_text,
                  :bio,
                  :headline,
                  :hireable,
                  :hireable_for_project,
                  :legacy_identifier,
                  :remember_token,
                  :featured_at

  validates :full_name, :presence => { if: :active? }

  validates :email,
            presence:   true,
            uniqueness: true,
            email:      true

  validates :password,
            :length => { minimum: 3 },
            :if     => :password

  validates :headline,
            :length => { maximum: 240 },
            :if     => :headline

  before_validation :ensure_name, :extract_headline

  before_validation :downcase_email, :if => :email_changed?

  before_save :create_remember_token

  has_many :users_emails

  def self.filter(filter = {}, results=User.unscoped)
    if term = filter[:term]
      results = search(term) if term.present?
    end

    event_ids = filter[:event_ids]
    if !event_ids.blank?
      event_ids = [event_ids].flatten
      results = results.includes(:event_users).merge(Events::User.where(event_id: event_ids))
    end

    platform_ids = filter[:platform_ids]
    if !platform_ids.blank?
      platform_ids = [platform_ids].flatten
      results = results.includes(:platforms).merge(Platform.where(id: platform_ids))
    end

    role_ids = filter[:role_ids]
    if !role_ids.blank?
      role_ids = [role_ids].flatten
      results = results.includes(:roles).merge(Role.where(id: role_ids))
    end

    hireable = filter[:hireable_for_project]
    if hireable
      results = results.where(hireable_for_project: hireable)
    end

    if locations = filter[:locations]
      locations = locations.select(&:present?).flatten.compact
      if locations.present?
        results = results.includes(:location).merge(Location.search(locations))
      end
    end

    filter[:page] ||= 1
    filter[:per_page] ||= 25
    results.paginate(filter.slice(:page, :per_page))
  end

  # Searches the User by the Full Name
  def self.search(query)
    query = "*" if query.blank?
    query  = query.gsub(/\s/,"+") + ":*"
    squery = sanitize_sql_array [ "to_tsquery('english', ?)", query ]
    conditions = "users.search_vector @@ #{squery}"
    order = "ts_rank_cd(users.search_vector, #{squery}) DESC"
    where(conditions).order(order)
  end

  def self.featured_users(limit = 5)
    self.featured.order('users.featured_at desc').limit(limit).includes(:profile, :roles, :platforms)
  end

  def migrated_from_legacy?
    !!(legacy_migrated_at)
  end

  def first_name
    full_name.to_s.split(" ")[0].humanize if full_name.present?
  end

  def last_name
    if full_name.present?
      temp = full_name.to_s.split(" ")
      temp.last.humanize if temp.size > 1
    end
  end


  def title_blank?
    name.blank?
  end

  def primary_email
    self.emails.first :conditions => {:primary => true}
  end

  def require_profile_setup?
    !(setup_skipped? || setup_completed?)
  end

  def setup_skipped?
    !!(setup_skipped_at)
  end

  def setup_completed?
    !!(setup_completed_at)
  end

  def can_edit?(obj)
    obj.can_edit?(self)
  end

  def can_judge?(obj)
    obj.can_judge?(self)
  end

  def signed_up?
    active?
  end

  def username
    profile.slug
  end

  def username=(val)
    build_profile unless profile.present?
    profile.slug = val
  end

  def setup_completed?
    roles.present? && headline.present? && !hireable_for_project.nil?
  end

  def check_completion
    if setup_completed? && !setup_completed_at
      update_column(:setup_completed_at, Time.zone.now)
    end
  end

  # def as_json(options = {})
  #   options = User.default_json_attrs.merge(options)
  #   super
  # end

  def self.default_json_attrs
    {
      only:    [ :id, :full_name ],
      methods: [ :slug,
                 :headline,
                 :image_url,
                 :bio,
                 :profile_url ]
    }
  end


  def tags
    unless @tags
      @tags = []
      @tags << location.city if location.present?
      @tags << roles.pluck(:title)
    end
    @tags.flatten
  end

  def platforms_text
    platforms.map(&:title)
  end

  def self.add(adder, params)
    unless user = User.find_by_email(params[:email])
      user = User.new params
      user.added_by_id = adder.id
      user.added_at = Time.now
      user.current_state = "added"
      user.save!
    end
    user
  end

  def save_eventbrite_token token
    self.eventbrite_token = token
    self.save
  end

  def add_link(label, url)
    link = self.profile.links.find_or_initialize_with_label(label.to_s)
    link.url = url
    link.save
  end

  def send_password_recovery_mail
    Notifier.password_recovery_mail(self).deliver
  end

  def pic_from_url pic_url
    self.photo_from_url = pic_url
  end

  def send_email_confirmation_mail
    Notifier.confirmation_mail_to_new_email(self).deliver
    Notifier.confirmation_mail_to_existing_email(self).deliver
  end

  def update_email
    self.confirm_email_code = nil
    self.confirm_email_status = 0
    self.email = temp_email
    self.temp_email = nil
    self.save!
  end

  def old_password_match
    if old_password.present? && self.salt.present?
      expected_password = BCrypt::Engine.hash_secret(old_password, self.salt)
      self.crypted_password == expected_password ? true : false
    end
  end

  def downcase_email
    self.email.downcase!
  end

  def ensure_name
    if email.present? && full_name.blank?
      self.full_name =  email.split("@")[0]
    end
  end

  def extract_headline
    self.headline ||= bio.split(".").first.truncate(240) if bio.present?
  end

  def projects_count
    projects.count
  end
  def events_count
    events.count
  end

  def create_remember_token
    self.remember_token = Digest::MD5.hexdigest("#{self.id} #{Time.now.to_i} #{self.salt}")
  end

  def generate_email_code
    Digest::MD5.hexdigest("#{self.id} #{Time.now}")
  end
  
  def god?
    self.email == "god@hackathon.io"
  end

  def self.location_contains(location)
    ids = Location.where("locatable_type = ? and lower(location_text) like ?", "User", "%#{location}%").collect(&:locatable_id)
    User.where("id in (?)", ids)
  end

  def self.stack_eq(platform_id)
    platform = Platform.find(platform_id)
    user_ids = Users::Platform.where("platform_id = ?", platform.id).collect(&:user_id)
    User.where("id in (?)", user_ids)
  end

  def self.role_in(ids)
    # fetching user_id from user_roles table with the role_id array
    user_ids = []
    n = 0
    ids.each do |role_id|
      if n == 0
        user_ids = UserRole.where("role_id = ?", role_id).collect(&:user_id)
      else
        user_ids = user_ids & UserRole.where("role_id = ?", role_id).collect(&:user_id)
      end
      n = n + 1
    end

    User.where("id in (?)", user_ids)
  end
end
