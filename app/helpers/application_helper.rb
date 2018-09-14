# encoding: utf-8
module ApplicationHelper
  include HackIO::Helpers::AutoLink
  include HackIO::Helpers::SluggedUrl
  include TrackingHelper
  include Renderers::Markdown

  def link_to_remote(*args, target)
    link_to(args, :data => {:remote => true, :target => target})
  end

  def render_flash_message
    render_partial 'shared/flash', flash: flash
  end

  def render_partial(path, locals=nil)
    render :partial => path, :locals => locals
  end

  def long_format_time(time)
    if time
      if time.is_a?(String)
        time = Time.parse(time)
      end
      time.strftime("%A, %B %d, %G %I:%M %p")
    else
      ""
    end
  end

  def long_format_date date
    date.strftime("%A, %B %d, %G")
  end

  def rt_quote
    "»"
  end

  def dot
    "·"
  end

  def rt_arrow
    "→"
  end

  def youtube_embed(url, options = {})
    opts = {
      width:  '413',
      height: '340'
    }.merge(options)

    pars = params_to_hash(URI.parse(url).query)
    %Q(
      <iframe
      width="#{opts[:width]}""
      height="#{opts[:height]}"
      src="http://www.youtube.com/embed/#{pars['v']}?rel=0"
      frameborder="0"
      allowfullscreen></iframe>).html_safe
  end

  def params_to_hash(query)
    query.present? ? Hash[query.split("&").map{ |parm| parm.split("=") }.compact] : {}
  end

  def register_event_url(event)
    "#{event.registration_url}?ref=hackathonio"
  end

  def message_button(users, caption="Message")
    users = [users].flatten unless users.is_a?(Array)
    raw %Q(<a href="#{new_message_path(receivers_ids: users.map(&:id))}"
           class="btn load-in-modal" data-remote="true">
            #{caption}
           </a>)
  end

  def render_open_graph_meta_tags(admins = ["516385695"])
    if @og_options.present?
      tags = {
        "og:title"       => "Hackathon IO",
        "og:type"        => "website",
        "og:url"         => root_url,
        "og:image"       => "#{request.protocol}#{request.host_with_port}#{image_path('preview.jpg')}",
        "og:description" => site_description,
        "og:site_name"   => "Hackathon IO",
        "fb:app_id"      => ENV['FACEBOOK_KEY'],
        "fb:admins"      => admins.join(",")
      }
      result = tags.merge(@og_options).collect { |tag, content| og_meta_tag(tag, content)}
      raw(result.join(" "))
    end
  end

  # Generates a OG meta tag
  def og_meta_tag(property, content)
    '<meta property="%s" content="%s" />' % [property, content]
  end

  def render_meta_description
    if @og_options.present?
      content = @og_options["og:description"]
    end
    content ||= site_description
    '<meta property="description" content="%s" />' % content
  end

  def site_description
    "The Home For Hackathons - World's best hackathons use hackathon.io to manage their event in a way never before thought possible."
  end

  # Main Page Tabs
  def main_tabs
    tabs = {
       :events     => 'Hackathons',
       :projects   => 'Projects',
       :network    => 'Network',
       # :challanges => 'Challenges'
       #:contests => "Contests"
    }.map do |key, label|
      %Q(<li class="nav-item#{' active' if params[:controller] == key.to_s}"><a href="#{url_for(key)}">#{label}</a></li>)
    end
    tabs.join.html_safe
  end

  def not_available(message = "Information not available", layout = true)
    html = %Q(<div class="not-available"> <i class="icon-exclamation-sign"></i> #{message}</div>)
    if layout
      html = %Q(
        <div class="pane">
          <div class="header">
            <div class="pane-title">
              #{html}
            </div>
          </div>
        </div>
      )
    end
    raw(html)
  end

  def not_available_inline(message)
    not_available(message, false)
  end

  def pager(obj, pars = {})
    pars = params.merge(pars)
    if next_page = obj.next_page
      id = "page_#{next_page}"
      content_tag(:span, :id => id) do
        link_to "More",
                pars.merge({:page => next_page}),
                :class => "button twelve secondary radius",
                :remote => true,
                "data-target" => "##{id}"
      end
    end
  end

end
