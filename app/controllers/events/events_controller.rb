class Events::EventsController < ApplicationController
  include FlowSessionHelper
  include EventsHelper
  layout             'events'
  respond_to         :json, :html, :js
  before_filter      :require_login , :except => [:index, :show, :chats, :live]
  load_resource      :event         , :expect => [:index ]
  authorize_resource :event         , :except => [:index ,  :new , :create, :chats, :live, :receive]
  after_filter       :track
  impressionist actions: [:show], unique: [:impressionable_type, :impressionable_id, :session_hash]

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to join_url, :alert => "Sorry, this event is private. If you would like be added please sign-up for the event via eventbrite"
  end

  def index
    @featured = Event.featured_events
    @events = Event.filter(params.slice(*Event::FILTERS)).includes(:profile, :location)
    @message = "No upcoming events "
    @message += "matching '#{params[:term]}' " if params[:term].present?
    @message += "near '#{params[:location]}'" if params[:location].present?
    respond_to do |format|
      format.js do
        if params[:page].present?
          render :partial => "events/teasers"
        else
          render :partial => "events/directory"
        end
      end
      format.html { render layout: 'application' }
    end
  end

  def show
    @user = current_user

    # if current_user && !@event.users.include?(current_user)
    #   @event_user = @event.event_users.new(:user_id => current_user.id)
    #   if @event_user.save
    #     flash.now[:notice] = "You have successfully joined the event"
    #   else
    #     flash.now[:error] = "Error adding you to the event"
    #   end
    #   @track_join = true
    # end

    respond_to do |format|
      format.html do
        @slug = @event.slug
        if @event.hashtag.present?
          @hashlink = "https://twitter.com/search?q=%23"+@event.hashtag
          
          # cache(@tweets, expires_in: 10.minutes) do
          #   begin
          #     @tweets = Twitter.search(@event.hashtag).results
          #     true
          #   rescue Twitter::Error, Instagram::Error => e
              
          #   end
          # end
        end
        @projects = @event.projects.order('created_at desc').limit(5)
        god = User.where(email: "god@hackathon.io").first
        @people   = @event.users.order('created_at desc').where("event_users.user_id is not ?", nil)
        if !god.nil?
          @people = @people.where(User.arel_table[:id].not_eq(god.id))
        end
        @organizers = @event.event_users.managers.where("event_users.user_id is not ?", nil).includes(:user).map(&:user)
        @sponsors = @event.sponsors.order('created_at desc').limit(12)
        @judges = @event.judges.includes(:user).limit(4).map { |j| j.user }
        @prizes = @event.prizes.sort_by(&:order).take(3)
        @schedules = @event.schedules.order(:day).limit(2)
        now = DateTime.now
        @next_timepoint = [@event.starts_at, @event.submission_deadline, @event.ends_at].compact.select {|t| t > now }.sort.first || now
        if @event.hacker_rank_enabled?
          @hr_score = HrScore.leader
        end
        @checklist = EventChecklistService.new(@event, @user)
      end
      format.json { render json: @event }
      format.js   { render :action => 'update' }
    end
  end

  def receive
    new_chat = Chat.new(params[:chat])
    new_chat.save!
    chat_item = create_chat_hash_from_chat(new_chat)
    respond_to do |format|
      format.json { render :json => chat_item }
    end
  end

  def tweets
    #show
  end

  def live
    @chats = []
    @current_chats = Chat.where(event_id:  @event.id, parent_id: nil).all
    @fetch_tweets = nil

    if @current_chats.present?
      @current_chats.each do |chat|
        new_hash = create_chat_hash_from_chat(chat)

        @chats << new_hash
      end
    end

    if @event.hashtag.present?
      cache(@tweets, expires_in: 10.minutes) do
        begin
          @tweets = Twitter.search(@event.hashtag).results
          
          @tweets.each do |tweet|
            new_hash = create_chat_hash_from_tweet(tweet)
            @chats << new_hash
          end
          @fetch_tweets = true
          true
        rescue Twitter::Error, Instagram::Error => e          
          @fetch_tweets = false
        end
      end
    end

    @slug = @event.slug
    @user = current_user
    puts "chats are as follows"
    @chats = @chats.sort_by {|k|k["post_time"]}.reverse
    respond_to do |format|
      format.json { render :json => {:chats => @chats, :slug => @slug, :event => @event, :user => @user, :tweet_status => @fetch_tweets}}
    end
  end

  def chats
    show
  end

  def new
    @event = Event.new
    @event.build_profile
    @event.build_location
    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  def create
    @event = Event.new(params[:event])
    @event.created_by = current_user
    god = User.where(email: "god@hackathon.io").first
    respond_to do |format|
      if @event.save
        @event.event_users.create(:user_id => current_user.id, :can_manage => true)
        if !@god.nil?
          @event.event_users.create(:user_id => god.id, :can_manage => true)
        end
        format.html { redirect_to(@event) }
      else
        if @event.errors.messages[:title].nil? and @event.errors.messages[:"profile.slug"].present?
          @event.errors.messages[:title] = ["#{@event.profile.slug} has already been taken"] 
        end
        format.html { render :action => "new", :layout => 'application' }
      end
    end
  end

  def update
    #respond_to do |format|
      #format.js do
        if @event.update_attributes(params[:event])
          flash[:info] = flash_messages[:update_successful]
          redirect_to :action => :show
        else
          #debugger
          flash[:error] = errors_for_record(@event)
          render :action => :edit
        end
      #respond_with(@event)
      #render :action => :update
      #end
    #end
  end

  def publish
    @event.update_attributes(params[:event])
    if @event.publish!
      flash[:info] = flash_messages[:event_published]
    else
      flash[:error] = "Could not publish event"
    end
    redirect_to @event
  end

  def judge
    #if !(event.judges.include?(current_user) || event.administrators.include?(current_user))
    #  raise AccessDenied
    #end
  end

  # Eventbrite Claims
  # =================

  def import
    respond_to do |format|
      format.html
      format.js
    end
  end

  def eb_admin_update
    @event = Event.find(params[:id])
    @event.update_column :eb_uid, params.fetch(:event){{}}[:eb_uid]
    redirect_to eb_claim_event_path(@event)
  end

  def eb_claim
    @event = Event.find(params[:id])
    session[:eb_uid]  = @event.eb_uid || @event.try(:event_source).try(:source_id)
    session[:return_to_url] = url_for(["eb_process_claim", @event])
    redirect_to "/auth/eventbrite"
  end

  def eb_process_claim
    @event = Event.find(params[:id])
    if ebuid = @event.eb_uid
      current_user.eventbrite_accounts.each do |eb|
        @success = true if eb.admin_for_eventbrite_event?(ebuid)
      end
      if @success
        flash[:info] = flash_messages[:claim_successful]
      else
        @event.update_column :eb_uid, nil
        flash[:error] = flash_messages[:eb_verify_error]
      end
    end

    redirect_to import_event_path(@event)
  end

  def eb_import_attendees
    @event = Event.find(params[:id])
    if ebuid = @event.eb_uid
      Resque.enqueue(ImportWorker, @event.id, current_user.id)
      flash[:info] = flash_messages[:eb_importing_atendees]
    else
      flash[:error] = flash_messages[:eb_not_found]
    end

    redirect_to import_event_path(@event)
  end

  def create_chat_hash_from_tweet(tweet)
    return {
              "screen_name" => tweet.user.screen_name,
              "picture" => tweet.user.profile_image_url,
              "content" => parse_tweet(tweet),
              "post_time" => tweet.created_at,
              "interval" => tweet_time(tweet),
              "parent_id" => nil,
              "tweet_id" => tweet.id,
              "id" => nil,
              "post_type" => 0,
              "replies" => []
            }
  end

  def create_chat_hash_from_chat(chat)
    return {
              "screen_name" => chat.user.full_name,
              "picture" => chat.user.image,
              "content" => chat.content.gsub(URI.regexp, '<a href="\0", target="_blank">\0</a>').html_safe,
              "post_time" => chat.created_at,
              "interval" => parse_time(chat),
              "parent_id" => chat.parent_id,
              "tweet_id" => nil,
              "id" => chat.id,
              "post_type" => 1,
              "replies" => chat.replies.map do |reply|
                create_chat_hash_from_chat(reply)
              end
            }
  end

protected



  def eb_account
    @eb_account ||= current_user.eventbrite_accounts.first
  end

  def event_participant
    if logged_in?
      @event_participant ||= event.event_participants.where(:user_id => current_user.id).first
    end
  end

  def event
    @event ||= Event.find(params[:event_id] || params[:id])
  end

  def managed_event
    @event ||= current_user.managed_events.find(params[:id] || params[:event_id])
  end

  def set_meta
    if @event.present?
      @page_title = @event.title
      @og_options = {
        "og:title"          => @page_title,
        "og:type"           => "hackathons:hackathon",
        "og:url"            => profile_url(@event),
        "og:image"          => @event.image_url,
        "hackathons:starts" => (@event.starts_at if @event.starts_at.present?),
        "hackathons:ends"   => (@event.ends_at if @event.ends_at.present?),
      }
      description = (@event.headline || @event.description || "")
      @og_options["og:description"] = description.gsub(/"/, "'").gsub(/\n/, ' ')
    end
  end

  def flash_messages
    _messages = {}

    _messages[:community_event] = <<-EOS
      This is a community managed event. If you are the organizer,
      <b>
        <a href="#{url_for([:eb_claim, @event])}"> verify</a>
        using eventbrite to claim this event.
      </b>
    EOS

    _messages[:eb_verify_error] = <<-EOS
      We could not verify your ownership from eventbrite,
      please email <a href="mailto:support@hackathon.io">support</a> for assitance.
    EOS

    _messages[:claim_successful] = <<-EOS
      #{event_profile_link} has been linked to Eventbrite.
    EOS

    _messages[:update_successful] = <<-EOS
      Settings for <b>#{event_profile_link}</b> has been successfully saved.
    EOS

    _messages[:event_published] = <<-EOS
      <b>#{event_profile_link}</b> has been published.
    EOS

    _messages[:eb_importing_atendees] = <<-EOS
      We are working on importing the attendees.
      Please check the <a href="#{event_users_path(@event)}">people page</a> later.
    EOS

    _messages[:eb_not_found] = <<-EOS
      Please
      <a href="#{import_event_path(@event)}">link this event to Eventbrite</a>
      first.
    EOS

    _messages
  end

  def event_profile_link(event = @event)
    %Q(<a href="#{event.profile_url}">#{@event.title}</a>)
  end

  def build_list_title
    @list_title = ["Hackathons"]
    @list_title << "happening" if params[:happening].present?
    @list_title << "around"
    @list_title << (params[:location].present? ?  params[:location] : "the world")
    @list_title = @list_title.join " "
  end

  def track
    if @event
      case params[:action]
      when 'create'
        KM.record "created event",    :event_id => @event.id, :event_title => @event.title
      when 'publish'
        KM.record "published event",  :event_id => @event.id, :event_title => @event.title
      when 'join'
        KM.record "joined event",     :event_id => @event.id, :event_title => @event.title
      when 'show'
        if @track_join
          KM.record "joined event",     :event_id => @event.id, :event_title => @event.title
        end
      end
    end
  end
end
