require_relative "../../app/helpers/events_helper"
require 'spec_helper'
describe EventsHelper do
  before do
    pending "need better way to test dates"
  end
  let(:view) { Class.new.extend(EventsHelper) }

  describe "#event_time_in_words" do
    let(:now) { Time.zone.now.in_time_zone("UTC") }

    it "returns now if the event is live" do
      event = double("event", :starts_at => now - 2.hours, :ends_at => now + 2.hours, :timezone => "UTC")
      view.event_time_in_words(event).should == "now"
    end

    it "returns time in words if event is not live" do
      event = double("event", :starts_at => now + 2.hours, :ends_at => now + 3.hours, :timezone => "UTC")
      view.event_time_in_words(event).should == "today"
    end
  end

  describe "#time_in_words" do
    it "returns 'today' if the date is today" do
      view.time_in_words(Time.now).should == "today"
    end

    it "returns 'tomorrow' for tomorrow" do
      view.time_in_words(Time.now + 1.day).should == "tomorrow"
    end

    it "returns day count for over 2 days" do
      view.time_in_words(Time.now + 3.day).should == "3 days"
    end

    it "returns days ago for past" do
      view.time_in_words(Time.now - 3.day).should == "4 days ago"
    end

    it "returns yesterday for yesterday" do
      view.time_in_words(Time.now - 1.day).should == "2 days ago"
    end
  end
end
