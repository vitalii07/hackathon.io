ActiveAdmin.register Project do
  menu priority: 3
  filter :title
  filter :slug
  filter :pitch
  filter :created_at
  filter :featured_at

  member_action :feature do
    resource.feature!
    redirect_to [:admin,resource], notice: "Project featured"
  end

  member_action :unfeature do
    resource.update_attributes featured_at: nil
    redirect_to [:admin,resource], notice: "Project unfeatured"
  end

  action_item only: :show do
    if project.featured?
      link_to 'Unfeature', unfeature_admin_project_path(project)
    else
      link_to 'Feature', feature_admin_project_path(project)
    end
  end

  index do
    selectable_column
    id_column
    column :featured?
    column "Logo" do |p|
      link_to(image_tag(p.profile.image.url(:thumb),height: '25', width: '25'),admin_project_path(p))
    end
    column(:title) {|p| auto_link(p)}
    column :created_by
    column :created_at
  end


  show do |project|
    attributes_table do
      rows :id, :title, :created_at, :created_by, :pitch
      row("Logo") {|p| image_tag(p.profile.image)}
      row("profile") {|p| link_to(profile_url(p))}
      row("featured") { |p| p.featured? }
    end

    panel "Links" do
      attributes_table_for(project) do
        rows :home_link,
          :github_link,
          :facebook_link,
          :twitter_link
      end
    end

    if project.members.count > 0
      panel "Team" do
        render partial: 'admin/users/users_table', locals: {users: project.members}
      end
    end

    if project.events_developed_at.present?
      panel "Events" do
        render partial: 'admin/events/events_table',
          locals: {events: project.events_developed_at}
      end
    end
  end

  form :html => { :enctype => "multipart/form-data" } do |f|
    f.inputs :title,
      :pitch,
      :description,
      :name => "Basics"

    f.inputs :name => "Profile", :for => :profile do |pf|
      pf.input :image
      pf.input :linkedin_link
      pf.input :github_link
      pf.input :facebook_link
      pf.input :twitter_link
      pf.input :home_link
    end
    f.buttons
  end


  controller do
    before_filter :only => :index do
      @per_page = 10
    end

    def index
      Project.includes(:profile)
      index!
    end

    def new
      @project = Project.new
      @project.build_profile
      new!
    end
  end
end
