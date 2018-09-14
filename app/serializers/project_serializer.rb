class ProjectSerializer < ActiveModel::Serializer
  include HackIO::Helpers::SluggedUrl

  attributes :id,
             :title,
             :pitch,
             :slug,
             :image_url,
             :url,
             :facebook_link,
             :twitter_link,
             :github_link,
             :home_link,
             :video_link,
             :blog_link

  has_many :platforms
  has_many :events, :embed => :ids
  has_many :memberships

  def url 
    slugged_url(url_for(object))
  end
end
