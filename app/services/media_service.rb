class MediaService < Struct.new(:source)

  def media(limit = nil)
    list = image_media(limit).concat(video_media(limit)).sort_by(&:position)

    if limit
      list.take(limit)
    else
      list
    end
  end

  def image_media(limit = nil)
    screenshots.map do |screenshot|
      Medium.new "image", screenshot.image, screenshot.updated_at
    end
  end

  def video_media(limit = nil)
    videos.map do |video|
      Medium.new "youtube", video.url, video.updated_at
    end
  end

  def screenshots(limit = nil)
    media_sources(:screenshots, limit)
  end

  def videos(limit = nil)
    media_sources(:videos, limit) + legacy_videos
  end

  def legacy_videos
    list = Array(source).map do |s|
      OpenStruct.new(url: s.video_url, updated_at: s.updated_at) if s.video_url.present?
    end

    list.compact
  end

  def media_sources(type, limit)
    if source.respond_to? type
      source.send(type).limit(limit)
    else
      Array(source.limit(limit).map {|s| s.send(type).first }.compact!)
    end
  end

  class Medium < Struct.new(:type, :data, :position)
    def url(mode = nil)
      if String === data
        data
      else
        data.url(mode)
      end
    end

    def image_url(mode = nil)
      if type == "youtube"
        id = data.match(/\W\w+\z/).to_a.last.to_s[1..-1] || data
        "http://img.youtube.com/vi/#{id}/2.jpg"
      else
        url mode
      end
    end

    def embed_url(mode = nil)
      if type == "youtube"
        id = data.match(/\W\w+\z/).to_a.last.to_s[1..-1] || data
        "http://www.youtube.com/embed/#{id}?rel=0"
      else
        url mode
      end
    end
  end
end