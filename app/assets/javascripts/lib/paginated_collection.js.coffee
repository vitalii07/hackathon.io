# Paginated Collection Mixin
# Provides pagniated iteration for Backbone Collection
#
# Usage:
#   _.extend(SomeCollection.prototype, Maya.Utils.PaginatedCollection)
#
#   list = new SomeCollection()
#   list.pageNext()
#   list.pagePrevious()
#   list.more()
#
#   list.pageInfo()
#
Maya.Utils.PaginatedCollection =

  initialize: ->
    _.bindAll(this, 'parse', 'url', 'pageInfo', 'nextPage', 'previousPage')
    @page = 1

  # Overiding fetch. Calls the #url for the base collection
  # and appends the pagination parameters
  #
  # Restores the orginal url once the fetch is complete
  fetch: (options) ->
    options || ( options = {} )
    @current_url = this.url
    url_string = if _.isFunction(@url) then @url.call() else @url
    @new_url  = this.pageUrl(url_string, @page)
    success = options.success
    self = this
    self.url = @new_url
    options.success = (resp) ->
      if(success) then success(self, resp)
      Maya.tile()
    Backbone.Collection.prototype.fetch.call(this, options)
    this.url = @current_url

  # Overding parse method for the collection
  # to return just the models.
  parse: (resp) ->
    @page     = parseInt(resp.page, 10)
    @per_page = parseInt(resp.per_page, 10)
    @total    = parseInt(resp.total, 10)
    resp.results

  # Pagination Information
  pageInfo: ->
    info =
      total:    @total
      page:     @page
      per_page: @per_page
      pages:    Math.ceil(@total/@per_page)
      prev:     false
      next:     false
    max = Math.min(@total, @page * @per_page)
    max = @total if @total is ( @page * @per_page )
    info.prev  = @page - 1 if @page > 1
    info.next  = @page + 1 if @page < info.pages
    info.range = [(@page - 1) * @per_page + 1, max]
    info

  # Fetches the next page,
  # calls the fetch() method
  nextPage: ->
    @page = @page + 1
    this.fetch()

  # Fetches the next page by calling fetch()
  # Appends the currently collection
  # without replacing it
  more: ->
    @page = @page + 1
    clone = _.clone(this)
    clone.bind('reset', this.updateCollection, this)
    clone.fetch()

  # Event Handler for the clone object in more
  # updates the current collection with the params
  updateCollection: (collection) ->
    this.add(collection.models, { silent: true } )
    # triggering the add event after adding all
    # the models is better for page performance
    this.trigger('add')

  # Fetches the previous page,
  # calls the fetch() method
  previousPage: ->
    @page = @page - 1
    this.fetch()

  pageUrl: (url, page, page_param = 'page') ->
    throw new Error "page must be defined" unless page
    throw new Error "url must be defined"  unless url
    params = this.getParams(url)
    params.page = page
    # select the first object as url
    url = url.split("?")[0]
    # Encode params
    params = $.param(params)
    "#{url}?#{params}"

  # Retruns an params hash of the
  # query strings from the url
  getParams: (url) ->
    params = {}
    url_parts = url.split("?")
    #the 2nd part of will be params
    if url_parts.length > 1
      param_parts = url_parts[1].split("&")
      for param in param_parts
        param = param.split("=")
        params[param[0]] = param[1]
    params
