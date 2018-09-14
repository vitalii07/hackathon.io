ActiveAdmin.register Event do
  menu priority: 1
  filter :id
  filter :slug
  filter :title
  filter :description
  filter :api, as: :select, :collection => Platform.order(:title)
  filter :country, as: :select, :collection => Location.event_countries
  filter :region,  as: :select
  filter :created_at
  filter :starts_at
  filter :ends_at
  filter :hosted
  filter :current_state, :as => :check_boxes, :collection => %w(draft published)
  filter :hosted

  member_action :publish do
    if resource.publish!
      flash[:notice] = "Event published"
    else
      flash[:error] = "Event could not be published."
    end
    redirect_to [ :admin, resource ]
  end

  member_action :unpublish do
    resource.unpublish!
    redirect_to [:admin, resource], notice: "Event is now in draft."
  end

  member_action :feature do
    resource.update_attributes featured_at: Time.zone.now
    redirect_to [:admin,resource], notice: "Event featured"
  end

  member_action :unfeature do
    resource.update_attributes featured_at: nil
    redirect_to [:admin,resource], notice: "Event unfeatured"
  end
  
  member_action :report do  
    
    # uploding the report to the aws s3
          
    respond_to do |format|
      format.csv { send_data resource.report}
    end
  end
  
  member_action :sponsor_report do
    sponsor = Organization.find(params[:sponsor_id])
    respond_to do |format|
      format.csv { send_data resource.report_for_sponsor(sponsor)}
    end
  end
  
  member_action :send_sponsor_report do
    sponsor = Organization.find(params[:sponsor_id])
    Utils::Report.send_event_report(resource, sponsor)
    redirect_to [:admin,resource], notice: "sent the report successfully"
  end
  
  collection_action :all_report do       
    respond_to do |format|
      format.csv { send_data Event.all_csv}
    end
  end

  collection_action :event_regions do
    regions = Location.event_regions(params[:country])
    respond_to do |format|
      format.js {render :json => regions}
    end
  end

  
  action_item only: :show do
    link_to "Report", report_admin_event_path(format: "csv") 
  end
  
  action_item only: :index do
    link_to "All Report", all_report_admin_events_path(format: "csv") 
  end

  action_item only: :show do
    link_to "Publish", publish_admin_event_path(event) if event.draft?
  end

  action_item only: :show do
    link_to "Unpublish", unpublish_admin_event_path(event) if event.published?
  end

  action_item only: :show do
    link_to 'View', profile_url(event) if event.published?
  end

  action_item only: :show do
    if event.featured_at.present?
      link_to 'Unfeature', unfeature_admin_event_path(event)
    else
      link_to 'Feature', feature_admin_event_path(event)
    end
  end

  batch_action :publish do |selection|
    Event.find(selection).each do |s|
      begin
        s.publish!
      rescue AASM::InvalidTransition => e
        @message = "Could not publish few items"
      end
    end
    redirect_to collection_path, notice: @message || "All selected events have been published."
  end

  index do
    # render hidden tag for the region query value
    if params[:q].present?
      render :partial => "search_query_info",
             :locals  => {:q_country => params[:q][:country_eq], :q_region => params[:q][:region_eq] }
    end
    
    selectable_column
    id_column
    column "Logo" do |event|
      link_to(image_tag(event.logo_url, :height => '25', :width => '25'), admin_event_path(event))
    end
    column(:title) { |event| auto_link(event) }
    column :starts_at
    column :ends_at
    column "Location", :sortable => 'location.city' do |event|
      if event.location.present?
        "#{event.location.city}, #{event.location.country}"
      end
    end
    column :current_state do |event|
      status_tag event.current_state
    end
    column :users_count
    column :sponsors_count
    column :projects_count
    column :created_at
    default_actions
  end

  sidebar "Details", only: :show do
    attributes_table_for resource do
      row :starts_at
      row :ends_at
      row("People")    { event.users_count    }
      row("Projects")  { event.projects_count  }
      row("Sponsors")  { event.sponsors_count  }
    end
  end

  sidebar "Logo", only: :show do
    div do
      image_tag resource.profile.image if resource.profile
    end
  end

  sidebar "Technical", only: :show do
    attributes_table_for resource do
      row("source") { auto_link(event.event_source) }
      row :legacy_identifier
      row :hacker_rank_enabled
    end
  end

  show do |event|

    panel "Description" do
      div do
        in_markdown(event.description).html_safe
      end
    end

    panel "Rules" do
      div do
        in_markdown(event.rules).html_safe
      end
    end

    if event.event_source.present?
      panel "Source" do
        attributes_table_for event.event_source do
          row :source_id
          row(:source_url) {|s| link_to(s.source_url, s.source_url, target: :blank)} 
          row(:title) { |source |auto_link(source) }
        end
      end
    end

    if event.location.present?
      panel "Location Information" do
        attributes_table_for event.location do
          rows :city, :country
        end
      end
    end
    
    if event.sponsors.present?
      panel "Sponsors" do
        render :partial => "sponsors_table",
             :locals  => { :sponsors => event.sponsors }
      end
    end

    if event.judges.present?
      panel "Judges" do
        render :partial => "judges_table",
               :locals => { :judges => event.judges }
      end
    end

    active_admin_comments
  end

  form :html => { :enctype => "multipart/form-data" } do |f|

    f.inputs "Event Details"  do
      f.input :title
      f.input :headline,  :as => :string
      f.input :description, hint: raw(link_to 'Markdown Syntax', 'http://daringfireball.net/projects/markdown/syntax', target:'_blank')
      f.input :starts_at, :as => :datetime_select
      f.input :ends_at,   :as => :datetime_select
      f.input :hacker_rank_enabled
    end

    f.inputs "Rules" do
      f.input :rules
    end

    f.inputs :name => "Location", :for => :location do |lf|
      lf.input :city
      lf.input :region
      lf.input :postal_code
      lf.input :country, :include_blank => true
    end

    f.inputs :name => "Profile", for: :profile do |pf|
      pf.input :image
    end
    
    f.inputs :name => "Secure" do
      f.input :private_event
    end

    f.buttons
  end

  controller do

    def new
      @event = Event.new
      @event.build_profile
      @event.build_location 
      new!
    end
  end
end
