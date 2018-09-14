# == Schema Information
#
# Table name: projects
#
#  id                  :integer          not null, primary key
#  title               :string(255)
#  pitch               :string(255)
#  url                 :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  legacy_identifier   :integer
#  created_by_id       :integer
#  video_url           :string(255)
#  description         :text
#  legacy_migrated_at  :datetime
#  setup_skipped_at    :datetime
#  setup_skipped_by_id :integer
#  setup_completed_at  :datetime
#  search_vector       :tsvector
#  is_open_source      :boolean
#  likes_count         :integer
#  hiring              :boolean
#

require 'spec_helper'

describe Project do
  let(:platform) { create(:platform) }

  let(:project) do
    proj = FactoryGirl.create(:project)
    proj.platforms << platform
    proj
  end

  let(:event) do
    event = create(:event)
    event.projects << project
    event
  end

  let(:project2) { create(:project) }

  it "has creator as a project member" do
    project.members.should(include(project.created_by))
  end

  describe "featured" do
    it "returns featured project" do
      proj = create(:project)
      proj.feature!
      Project.featured.should == [proj]
    end
  end

  describe "featured_projects" do
    it "returns all featured project in desc" do
      proj1 = create(:project)
      proj2 = create(:project)
      proj1.feature!
      proj2.feature!
      Project.featured_projects.should == [proj2, proj1]
    end
  end

  describe "#filter" do

    it "filters by events" do
      projects = Project.filter(:event_ids => [ event.id ])
      projects.should =~ [project]
    end

    it "filters by platforms" do
      projects = Project.filter(:platform_ids => [ platform.id ])
      projects.should =~ [project]
    end

    it "filters by term" do
      project.update_attributes(:description => "test title")
      projects = Project.filter(:term => "test")
      projects.should =~ [project]
    end

    it "should filter by hiring" do
      project.update_attributes(:hiring => true)
      projects = Project.filter(:hiring => true)
      projects.should =~ [project]
    end
  end
end
