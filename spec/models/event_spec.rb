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

require 'spec_helper'

describe Event do
  let(:sf_text)     { "San Francisco, CA"                       }
  let(:today)       { Time.zone.now.strftime("%x")              }
  let(:yesterday)   { 1.day.ago.strftime("%x")                  }
  let(:tomorrow)    { (Time.zone.now + 1.day).strftime("%x")    }
  let(:in_1_month)  { (Time.zone.now + 1.month).strftime("%x")  }
  let(:in_2_months) { (Time.zone.now + 2.months).strftime("%x") }
  let(:in_4_months) { (Time.zone.now + 4.months).strftime("%x") }

  let(:launch)      { create(:event , :start_date_text => 10.days.ago.strftime("%x"), :location_text => sf_text) }
  let(:angelhack)   { create(:event , :start_date_text => tomorrow    , :location_text => sf_text) }
  let(:angelhack2)  { create(:event , :start_date_text => in_1_month  , :location_text => sf_text) }
  let(:angelhack3)  { create(:event , :start_date_text => in_2_months , :location_text => sf_text) }
  let(:angelhack4)  { create(:event , :start_date_text => in_4_months , :location_text => sf_text) }
  let(:hearst)      { create(:event , :start_date_text => in_4_months , :location_text => "New York", :featured_at => Time.zone.now) }

  describe "#upcoming" do
    it "returns upcoming events" do
      Event.upcoming.should == [ hearst, angelhack ]
    end
    it "doesn't return past events" do
      Event.upcoming.should_not include(launch)
    end
  end

  describe "#near" do
    before { Location.stub(:near) { Location.where(:id => [ angelhack.location.id, angelhack2.location.id ]) } }

    it "returns events near a location" do
      Event.near("San Franciso, CA").should == [ angelhack, angelhack2 ]
    end

    it "doesn't return unmatched locaitons" do
      Event.near("San Franciso, CA").should_not include hearst
    end
  end

  describe "#this_week" do
    before { pending "fix dates in test" }
    it "returns events in the current week" do
      Event.this_week.should == [ angelhack ]
    end

    it "doesn't return events in the future or past" do
      Event.this_week.should_not include [launch, angelhack2]
    end
  end

  describe "#next_30_days" do
    xit "returns events in the next 30 days" do
      Event.next_30_days.should == [ angelhack, angelhack2 ]
    end
    xit "doesn't return events in the future or past " do
      Event.next_30_days.should_not include [ launch, angelhack3 ]
    end
  end

  describe "#next_90_days" do
    it "returns events in the next 90 days" do
      Event.next_90_days.should == [ angelhack, angelhack2, angelhack3 ]
    end
    it "doesn't return events in the future or past" do
      Event.next_90_days.should_not include [ launch, hearst ]
    end
  end

  describe "#search" do
    let(:launch)    { create(:event, :title => "Launch Hackathon") }
    let(:angelhack) { create(:event, :title => "AngelHack") }

    it "returns matched results" do
      Event.search("angelhack").should == [angelhack]
    end

    it "returns all events when query is nil" do
      Event.search(nil).should == Event.all
    end

    it "does not return unmatched results" do
      Event.search("angelhack").should_not include(launch)
    end
  end

  describe "#find_upcoming" do
    let(:results) do
      Event.stub(:near) { Event.where :id => [angelhack.id, angelhack2.id, angelhack3.id] }
      Event.find_upcoming(:location => sf_text, :min_events => 3, :radius => 500)
    end

    it "returns upcoming events near a location" do
      results.should == [ angelhack, angelhack2, angelhack3 ]
    end

    it "doesn't return unmatched events" do
      results.should_not include(launch, hearst)
    end
  end

  describe "#save_starts_at" do
    it "saves starts at" do
      event = Event.new(:start_date_text => "01/14/2012")
      event.send(:save_starts_at)
      event.starts_at.should == Time.new(2012,01,14, 0, 0, 0, "+00:00")
    end
  end

  describe "#save_ends_at" do
    it "saves ends at" do
      event = Event.new(:end_date_text => "01/14/2012")
      event.send(:save_ends_at)
      event.ends_at.should == Time.new(2012, 01, 14, 0, 0, 0, "+00:00")
    end
  end

  describe "#save" do
    let(:starts_utc) { Time.new(2012,05,20,5,0,0,"+00:00") }
    let(:ends_utc)   { Time.new(2012,05,22,8,0,0,"+00:00") }
    let(:event) do
      create(:event,
             :title           => "event major",
             :start_date_text => starts_utc.strftime("%x"),
             :start_time_text => "05:00 AM",
             :location_text   => "San Francisco, CA")
    end

    context "valid attributes" do

      it "defaults ends at 1 day" do
        event.ends_at.should == event.starts_at + 1.day
      end

      it "has an event profile" do
       event.profile.should be_present
      end

      it "has a slug" do
        event.profile.slug.should == 'event'
      end

      it "has start date in UTC" do
        event.starts_at.should == starts_utc
      end

      it "has end date in UTC" do
        event.end_date_text = ends_utc.strftime("%x")
        event.end_time_text = "8:00 AM"
        event.save
        event.ends_at.should == ends_utc
      end

      it "has a location" do
        event.location.location_text.should == "San Francisco, CA"
      end

      it "creates default schedules for each day" do
        event.schedules.count.should == 2
      end
    end

    context "invalid attributes" do
      it "has errors if start date is invalid" do
        event = build(:event, :start_date_text => nil)
        event.save
        event.errors[:start_date_text].should include("can't be blank")
      end
    end
  end

  describe "#publish!" do
    it "sets the state to publish" do
      event = create(:event, :current_state => 'draft')
      event.publish!
      event.reload.current_state.should == 'published'
    end
  end

  describe '#feature!' do
    let (:new_event) { create(:event) }
    it "should change featured to true" do
      new_event.feature!
      new_event.featured?.should == true
      new_event.featured_at.should_not == nil
    end
  end

end
