class Maya.Collections.Submissions extends Backbone.Collection
  model: Models.Submission

  params: {}

  initialize: (event) ->
    @event = event
    @params['event_id'] = event?.id
    @debouncedFetch = _.debounce((=> @fetch()), 200)
    @

  parse: (data) -> data?.submissions

  setEventId: (event_id) ->
    @params['event_id'] = event_id
    @event_id = event_id
    @

  for: (event) ->
    if event?
      @event = event
      @setEventId(event.id)
    @

  search: (term) ->
    @page = 1
    @params['term'] = term
    @debouncedFetch()
    @

  comparator: (submission) -> submission.getOrder()

  # Returns the first new (non voted) submission
  firstNewSubmission: ->
    for submission in @models
      return submission unless submission.hasUserVoted()
    return undefined

  url: ->
    @event_id = @params['event_id']
    throw new ArgumentError("params.event_id must be set") unless @event_id?
    "/events/#{@event_id}/submissions.json?#{$.param(@params)}"

  sortByOrder: ->
    sorted = new Collections.Submissions(@models)
    sorted.comparator = (submission) -> submission.getOrder()
    sorted.sort()
