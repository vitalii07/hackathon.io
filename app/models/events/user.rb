# == Schema Information
#
# Table name: event_users
#
#  id              :integer          not null, primary key
#  event_id        :integer
#  user_id         :integer
#  confirmed_at    :datetime
#  confirmed_by_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  role            :string(255)
#  can_manage      :boolean
#  send_invite     :boolean
#  can_judge       :boolean
#

class Events::User < ActiveRecord::Base
  attr_accessor :full_name, :email

  attr_accessible  :user_id, :event_id,
                   :email, :full_name, :can_manage, :can_judge, :send_invite, :joined, :liked

  belongs_to :user, :class_name => "::User"

  belongs_to :event, :counter_cache => :users_count

  before_validation :find_user

  validate :user_or_email_must_be_present

  validates_presence_of :event_id
  validates_uniqueness_of :user_id, scope: [:event_id], allow_blank: true, allow_nil: true

  delegate :email_sent_at, to: :invitation

  delegate :email_sent?,   to: :invitation

  has_one  :invitation, :as => :invitable, :dependent => :destroy

  has_many :platforms, :through => :user

  has_many :roles, :through => :user

  scope :managers, ->(bool = true) { where(can_manage: bool) }

  def self.filter(filters = {})
    results = self
    return results if filters.blank?
    if event_id = filters["event_id"]
      results = results.where(:event_id => event_id)
    end

    if term = filters["term"]
      if term.present?
        user_ids = User.search(term).pluck(:id)
        results = results.where(:user_id => user_ids)
      end
    end

    if platform_ids = filters["platform_ids"]
      platform_ids = platform_ids.select(&:present?).flatten.compact
      if platform_ids.present?
        results = results.includes(:platforms).merge(Platform.where(id: platform_ids))
      end
    end

    if role_ids = filters["role_ids"]
      role_ids = role_ids.select(&:present?).flatten.compact
      if role_ids.present?
        results = results.includes(:roles).merge(Role.where(id: role_ids))
      end
    end

    if hirable = filters["hireable_for_project"]
      results = results.includes(:user).merge(User.where(hireable_for_project: hirable))
    end

    if locations = filters["locations"]
      locations = locations.select(&:present?).flatten.compact
      if locations.present?
        results = results.includes(user: :location).merge(Location.search(locations))
      end
    end

    results.includes(:user => [:roles,:platforms, :profile])
  end

  def create_invitation_if_required
    build_invitation unless invitation.present?
    if send_invite? && !email_sent?
      create_invitation
    end
  end

  def create_invitation
    self.invitation = super(:guest => user, :purpose => invite_purpose, :purpose_data => { event_id: event.id }, :email => email)
  end

  def invite_purpose
    if can_manage?
      return :manage_event
    elsif can_judge?
      return :judge_event
    else
      return :join_event
    end
  end

  def self.manager_ids
    managers.pluck(:user_id)
  end

  def self.invite(params)
    event_user = new(params)
    event_user.send_invite = true
    if event_user.save
      event_user.create_invitation_if_required
      if event_user.invitation.present?
        event_user.invitation.process!
      end
      true
    else
      false
    end
  end


private

  def find_or_create_user
    if user_id.blank? && email.present?
      user = User.where(email: email).first_or_create(
        full_name: full_name,
        current_state: "invited"
        )
      self.user = user
    end
  end

  def find_user
    if user_id.blank? && email.present?
      user = User.where(email: email).first
      self.user = user
    end
  end

  def user_or_email_must_be_present
    if user_id.blank? && email.blank?
      errors.add(:email, "is required")
    end
  end
end
