Handlebars.registerHelper 'time_in_mins', (date) ->
  if date?
    dateO = new Date(date)
    if !isNaN(dateO.getTime())
      dateO.toFormat("HH:MI PP")
    else
      new Date(date+' 1/1/1990').toFormat("HH:MI PP")

  else ""

Handlebars.registerHelper 'format_date', (date) ->
  if date? then new Date(date).toFormat("DDD, MMMM D, YYYY") else ""

Handlebars.registerHelper 'format_tags', (tags) ->
  tags.join(" · ")

Handlebars.registerHelper 'raw_string', (text) ->
  new Handlebars.SafeString(text)

Handlebars.registerHelper 'format_rating', (float) ->
  if float? then Math.round(float*100)/100

Handlebars.registerHelper 'render_stack', (platforms) ->
  if platforms.length > 0
    new Handlebars.SafeString('<i class="icon-cogs"></i>&nbsp;&nbsp;&nbsp;'+(platforms.map (platform) -> platform.title).join(' · '))
  else
    ""

Handlebars.registerHelper 'youtube_embed', (url) ->
  try
    throw 'not youtube' if url.replace('youtube', '') == url
    id = /[?&]{1}v=([^&]+)/g.exec(url).pop()
    throw 'no id' if !id
    new Handlebars.SafeString("""
      <iframe
        width  = "413"
        height = "340"
        src = "http://www.youtube.com/embed/#{id}?rel=0"
        frameborder="0"
        allowfullscreen></iframe>
    """)
  catch error
    console.log error
    new Handlebars.SafeString('<div class="not-available">Demo not availables</div>')