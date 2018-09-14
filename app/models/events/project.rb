# == Schema Information
#
# Table name: event_projects
#
#  id              :integer          not null, primary key
#  project_id      :integer
#  event_id        :integer
#  created_by_id   :integer
#  confirmed_by_id :integer
#  confirmed_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Events::Project < ActiveRecord::Base

  FILTERS = [ :term, :page, :per_page, :hiring ]

  belongs_to :project, :class_name => "::Project"
  belongs_to :event,   :class_name => "::Event", :counter_cache => :projects_count

  validates_presence_of :event, :project

  accepts_nested_attributes_for :project

  attr_accessible :event_id,
                  :project_id,
                  :event,
                  :project,
                  :project_attributes

  after_save :remove_duplicates, :submit_project
  has_many :platforms, :through => :project

  # filters: term, hiring
  # set filter[:page] = 0 for no pagniation
  def self.filter(filter = {})
    results = self
    if term = filter[:term]
      if term.present?
        results = where :project_id => Project.search(term).pluck('projects.id')
      end
    end

    if event_id = filter["event_id"]
      results = results.where(:event_id => event_id)
    end

    if hiring = filter[:hiring]
      results = results.includes(:project).merge(::Project.where(hiring: hiring))
    end

    if platform_ids = filter["platform_ids"]
      platform_ids = platform_ids.select(&:present?).flatten.compact
      if platform_ids.present?
        results = results.includes(project: :platforms).merge(Platform.where(id: platform_ids))
      end
    end

    if filter[:page] == 0 # don't paginate
      return results
    end
    # else paginate
    results
  end

  def remove_duplicates
    event.event_projects.where(:project_id => project.id).each do |d|
      d.destroy unless d.id == self.id
    end
  end

  def submit_project
    unless Submission.where(:event_id => event.id, :project_id => project.id).present?
      Submission.create(:event_id => event.id, :project_id => project.id)
    end
  end

  def as_json(opts = {})
    opts = EventProject.default_json_attributes.merge(opts)
    super
  end

  def self.default_json_attributes
    {
      only:    [ :id,
                 :looking,
                 :created_at,
                 :project_id,
                 :event_id
               ],
      include: [ :project =>
                 { :only => [
                    :id,
                    :title,
                    :pitch,
                    :created_at ],
      methods: [ :profile_url,
                 :platforms_text,
                 :logo_url ]
               }]
    }
  end

  def self.default_json_attributes_full
    {
      only:    [ :id,
                 :looking,
                 :created_at,
                 :project_id,
                 :event_id
               ],
      include: [ project: Project.default_json_attrs ]
    }
  end

end
