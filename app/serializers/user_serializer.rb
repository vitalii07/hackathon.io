class UserSerializer < ActiveModel::Serializer
  include HackIO::Helpers::SluggedUrl
  attributes :id,
             :full_name,
             :bio,
             :image_url,
             :headline,
             :url,
             :facebook_link,
             :twitter_link,
             :github_link,
             :linkedin_link,
             :home_link,
             :blog_link

  has_many :platforms
  has_many :roles
  has_one  :location

  def url
    slugged_url(url_for(object))
  end
end
