module EventsHelper
  def set_event_tabs(event= @event)
    if event
      @page_tabs = {
        :show         =>  { label: "Overview",  url: event_path(event)                   } ,
        #:wikis        =>  { label: "Wiki",      url: event_wiki_path(event)              } ,
        #:activities   =>  { label: "Activities",url: event_activities_path(event)        } ,
        :schedules    =>  { label: "Schedule",  url: event_schedules_path(event)         } ,
        :rules        =>  { label: "Rules",     url: event_rules_path(event)             } ,
        :chat         =>  { label: "Chats",     url: chats_event_path(event)             } ,
        :users        =>  { label: "People",    url: event_users_path(event)             } ,
        :projects     =>  { label: "Projects",  url: event_projects_path(event)          } ,
        :photos       =>  { label: "Twitter Feed",    url: event_photos_path(event)            } ,
        :prizes       =>  { label: "Prizes",    url: event_prizes_path(event)            } ,
        :judge        =>  { label: "Judging",   url: judge_event_submissions_path(event) }

        #:sponsors     =>  { label: "Sponsors",  url: event_sponsors_path(event)          } ,
      }
      #@page_tabs[:chat] = { label: "Chats", url: chats_event_path(event) }
      if can? :import, event
        @page_tabs[:import] = {label: "Import", url: import_event_path(event)}
      end

      if can? :email, event
        @page_tabs[:email] = {label: "Emails", url: event_emails_path(event)}
      end

      

      #if can? :judge, event
      #  @page_tabs[:judge] = { label: "Judging",   url: judge_event_submissions_path(event) }
      #end
    end
  end

  def event_already_claimed? claim_notice
    claim_notice.to_i == 1 ? true : false
  end

  def event_claimed_by_current_user event
    event.claimed_user_id == current_user.id ? true : false
  end

  def is_event_user?(event = @event)
    current_user && current_user.events.include?(event)
  end

  def event_time_in_words(event)
    now = Time.zone.now.in_time_zone(event.timezone)
    if now.between?(event.starts_at, event.ends_at)
      "now"
    else
      time_in_words(event.starts_at, event.timezone)
    end
  end

  def time_in_words(time, timezone = Time.zone)
    now = Time.zone.now.in_time_zone(timezone)
    day_begins = now.at_beginning_of_day
    if time.between?(now.at_beginning_of_day, now.at_beginning_of_day + 24.hours)
      "today"
    elsif time.between?(day_begins + 24.hours, day_begins + 48.hours)
      "tomorrow"
    elsif time > now + 24.hours
      "#{((time - now) / 3600 / 24).ceil} days"
    elsif time < now - 24.hours
      "#{((now - time) / 3600 / 24).ceil} days ago"
    elsif time.between?(day_begins - 24.hours, day_begins)
      "yesterday"
    end
  end

  def parse_tweet(tweet)
    begin
      puts tweet.text
      tweet.hashtags.each do |hashtag|
        name = hashtag.attrs[:text]
        puts name
        tweet.text["##{name}"] = "<a href='https://twitter.com/search?q=%23#{name}', target='_blank'> ##{name} </a>" if tweet.text.include? name
      end
      tweet.user_mentions.each do |user|
        name = user.attrs[:screen_name]
        puts name
        if tweet.text.present?
          tweet.text["@#{name}"] = "<a href='https://twitter.com/#{name}', target='_blank'> @#{name} </a>" if tweet.text.include? name
        end
      end
      tweet.urls.each do |url|
        name = url.url
        puts name
        tweet.text["#{name}"] = "<a href='#{name}', target='_blank'> #{name} </a>" if tweet.text.include? name
      end
      print "\n \n"
      "<div class=\"tweet-detail\"> #{tweet.text} </div>".html_safe
    rescue
      # do nothing
    end
  end

  def parse_time(chat)
    diff = (Time.now - chat.created_at).to_i
    if diff < 60
      "1m"
    elsif diff < 60*60
      "#{diff/60}m"
    elsif diff < 60*60*24
      "#{diff/60/60}h"
    else
      "#{diff/60/60/24}d"
    end
  end

  def tweet_time(tweet)
    diff = (Time.now - tweet.created_at).to_i
    if diff < 60
      "1m"
    elsif diff < 60*60
      "#{diff/60}m"
    elsif diff < 60*60*24
      "#{diff/60/60}h"
    else
      "#{diff/60/60/24}d"
    end
  end

  def submission_csv(submissions)
    CSV.generate do |csv|
      csv << ["Name", "Judge Votes", "Judge Score", "Crowd Votes", "Crowd Score"]
      submissions.each do |submission|
        csv << [submission.project.title,
                submission.judge_count,
                submission.mean_rating,
                submission.crowd_count,
                submission.mean_crowd_rating]
      end
    end
  end

end
