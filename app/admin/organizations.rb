ActiveAdmin.register Organization do
  index do
    selectable_column
    id_column
    column :logo do |org|
      image_tag(org.profile.image, width: 25) if org.profile.image
    end
    column(:title, :sortable => :title)   { |o| auto_link(o) }
    column(:profile) { |o| link_to(nil, profile_url(o), :target => :blank) }
    default_actions
  end

  show do |org|
    attributes_table do
      rows :id, :title, :description, :angellist_uid
      row(:logo) do
        image_tag(org.profile.image)
      end
    end

    render org.profile

    panel "Sponsored Events" do
      render :partial => "admin/events/events_table",
             :locals  => { :events => org.sponsored_events }
    end
  end

  form :html => { :enctype => "multipart/form-data" } do |f|
    f.inputs "Details" do
      f.input :title
      f.input :headline
      f.input :domain_name
      f.input :description,
              :hint => raw(link_to 'Markdown Syntax', 'http://daringfireball.net/projects/markdown/syntax', target:'_blank')
    end
    f.inputs :name => "Profile", :for => :profile do |pf|
      pf.input :slug
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
    def new
      @organization = Organization.new
      @organization.build_profile
      new!
    end
  end
end
