FactoryGirl.define do
  # events
  factory :event do
    title
    timezone        'UTC'
    start_date_text '08/25/2012'
    start_time_text '10:00 AM'
    location_text   'London'
    current_state   'published'
    submission_deadline   { Time.zone.parse "2012-08-26 17:00:00" }
    public_event    true

    factory :published_event do
      association :location, factory: :sf_location
      current_state 'published'
      public_event true
      starts_at { Time.zone.parse "2012-08-25 17:00:00" }
      submission_deadline   { Time.zone.parse "2012-08-26 17:00:00" }
      ends_at   { Time.zone.parse "2012-08-26 17:00:00" }
    end

    factory :sf_event do
      timezone 'Pacific Time (US & Canada)'
      association :location, factory: :sf_location
      current_state 'published'
      starts_at { Time.parse "2012-08-25 17:00:00" }
      submission_deadline   { Time.zone.parse "2012-08-26 17:00:00" }
      ends_at   { Time.parse "2012-08-26 17:00:00" }
    end

    factory :bo_event do
      timezone 'Eastern Time (US & Canada)'
      association    :location, factory: :bo_location
      current_state 'published'
      starts_at { Time.parse "2012-08-25 17:00:00" }
      submission_deadline   { Time.zone.parse "2012-08-26 17:00:00" }
      ends_at   { Time.parse "2012-08-26 17:00:00" }
    end

    factory :no_location_event do
      current_state 'published'
      starts_at { Time.parse "2012-08-25 17:00:00" }
      submission_deadline   { Time.zone.parse "2012-08-26 17:00:00" }
      ends_at   { Time.parse "2012-08-26 17:00:00" }
    end
  end

  factory :event_prize, :class => "Events::Prize" do
    title
    prize_value 100
    association :sponsoring_org, :factory => :organization
    association :event
  end
end
