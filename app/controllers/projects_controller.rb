class ProjectsController < ApplicationController
  layout 'application', :only => [ :index, :new, :create ]
  impressionist actions: [:show], unique: [:impressionable_type, :impressionable_id, :session_hash]

  before_filter :require_login, :only => [ :new, :update, :create, :edit ]
  respond_to    :json, :html, :js

  def index
    filters = params.slice(*Project::FILTERS)
    if filters.present?
      if filters[:platform_ids] && filters[:platform_ids].present?
        #if params[:new_platform]
        #  filters[:platform_ids] << params[:new_platform]
        #  debugger
        #end
        filters[:platform_ids].select!(&:present?)
        filters[:platform_ids].compact!
      end
      if filters[:event_ids] && filters[:event_ids].present?
        filters[:event_ids].select!(&:present?)
        filters[:event_ids].compact!
      end
    end
    @projects = Project.filter(filters)
    #@p_ids = filters[:platform_ids] ||= []
    @projects = @projects.order('projects.updated_at desc').includes(:profile)
    @featured_projects = Project.featured.limit(5).includes(:profile)
    respond_to do |format|
      format.html
      format.js   do
        if params[:page].present?
          render :partial => 'projects/teasers'
        else
          render :partial => 'projects/directory'
        end
      end
      format.json { render :json => @projects }
    end
  end

  def show
    @project = Project.find(params[:id])
    @media   = MediaService.new(@project).media
    @members = @project.members.includes([:profile])
    @page_title = @project.title
    @events_developed_at = @project.events_developed_at.all
    @og_options = {
      "og:type"  => "hackathons:project",
      "og:title" => @page_title,
      "og:description" => (@project.pitch.present? ? @project.pitch : @project.description).gsub(/"/, "'").gsub(/\n/, ' '),
      "og:url"   => profile_url(@project),
      "og:image" => @project.image_url
    }
    if current_user.present? && (@project.created_by.id == current_user.id or current_user.god?)
      @can_edit = true
    end
    respond_with(@project)
  end

  def new
    @project = Project.new
    @project.profile || @project.build_profile
    @project.screenshots.build
    respond_with(@project)
  end

  def create
    @project = Project.new params[:project]
    @project.created_by = current_user
    respond_to do |format|
      if @project.save
        ActiveRecordService.set_or_create_many(@project.platforms, :title, params[:platforms].split(","))
        format.html { redirect_to @project.profile_url }
      else
        flash[:error] = errors_for_record(@project)
        format.html { redirect_to :back }
      end
      format.json { render json: @project }
    end
  end

  def edit
    # @project = current_user.projects.find(params[:id])
    @project = Project.find(params[:id])
    respond_with(@project)
  end

  def edit_team
    set_side_nav
    @project = current_user.projects.find(params[:id])
    render :layout => "settings"
  end

  def edit_opensource
    set_side_nav
    @project = current_user.projects.find(params[:id])
    render :layout => "settings"
  end

  def edit_screenshots
    set_side_nav
    @project = current_user.projects.find(params[:id])
    @screenshots = @project.screenshots
    render :layout => "settings"
  end

  def update
    # @project = current_user.projects.find(params[:id])
    @project = Project.find(params[:id])
    if @project.update_attributes(params[:project])
      ActiveRecordService.set_or_create_many(@project.platforms, :title, params[:platforms].split(","))
      flash[:info] = %Q(Settings for <b><a href="#{@project.profile_url}">#{@project.title}</a> have been updated.</b>)
    else
      flash[:error] = errors_for_record(@project)
    end
    respond_with(@project)
  end

  def like
    @project = Project.find params[:id]

    authorize! :like, @project

    @like = @project.likes.where(user_id: current_user.id).create

    respond_to do |format|
      format.js { head(@like.persisted? ? :created : :conflict) }
    end
  end

  def unlike
    @project = Project.find params[:id]

    authorize! :like, @project

    @likes = @project.likes.where(user_id: current_user.id)
    @exists = @likes.size > 0
    @likes.destroy_all

    respond_to do |format|
      format.js { head(@exists ? :ok : :no_content) }
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to events_url
  end

  def viewed_users
    @project = Project.find(params[:id])
    @users = @project.viewed_users
    # god = User.where(email: "god@hackathon.io").first
    # if @users.include?(god)
    #   @users.delete(god)
    # end
  end

  def liked_users
    @project = Project.find(params[:id])
  end

  private

  def set_side_nav
    @menu_object = project
    @menu_style = 'single'
    @menu_items = {
        :edit => "Profile",
        :edit_team => "Team Members",
        :edit_screenshots => "Screenshots"
    }
  end

  def respond_for_flow
    if @project.save
      proceed_current_flow(project_id: @project.id)
    else
      render "projects_flow/#{session[:projects_flow_current_step]}", layout: "prima"
    end
  end

  def respond_for_project
    respond_to do |format|
      format.html { redirect_to @project.profile_url  }
      format.json { render json: @project }
    end
  end

  def project
    if id = ( params[:id] || params[:project_id] )
      @project = Project.includes(default_includes)
      .where(id: id)
      .first
    end
  end

  def default_includes
    [
      [ :profile => [:links]   ],
      [ :members => [:profile] ]
    ]
  end

  def set_page_tabs
    if project
      @page_tabs = {
        show: { label: "Overview", url: profile_url(project) }
      }
    end
  end


  def paged_response
    #respond_to do |format|
      #format.json do
        #@projects = @projects.includes([:platforms, :profile])
        #@total = @projects.count
        #@paged = {
          #'total'     => @total,
          #'page'      => params[:page] || 1,
          #'per_page'  => Project.per_page,
          #'results'   => @projects.paginate(page: params[:page]).all
        #}
        #respond_with(@paged)
      #end

      #format.html do
        #respond_with(@paged)
      #end
    #end
  end
end
