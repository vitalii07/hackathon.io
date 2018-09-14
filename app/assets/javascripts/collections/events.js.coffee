# Collections for Events and event related


# Event People
# ============
Maya.Collections.EventPeople = Backbone.Collection.extend

  model_name: "event_people"

  params: {}

  initialize: (event_id) ->
    @params   = {}
    @event_id = event_id

  setEventId: (event_id) ->
    @event_id = event_id
    this

  hirableOn: ->
    @page = 1
    @params['hirable'] = 'true'
    this.fetch()

  hirableOff: ->
    @page = 1
    delete @params['hirable']
    this.fetch()

  search: (term) ->
    @page = 1
    @params['term'] = term
    this.fetch()


  # TODO: Replace with setEventId
  for: (event_id) ->
    @event_id = event_id
    this

  url: ->
    _url = "/events/#{@event_id}/#{@model_name}?#{$.param(@params)}"

_.extend Maya.Collections.EventPeople.prototype, Maya.Utils.PaginatedCollection


class Maya.Collections.EventAdministrators extends Collections.EventPeople
  model: Maya.Models.EventPerson
  url: ->
    "/events/#{@event_id}/event_administrators"

class Maya.Collections.EventAttendees extends Collections.EventPeople
  model: Maya.Models.EventPerson
  url: -> "/events/#{@event_id}/event_participants"

class Maya.Collections.EventJudges extends Collections.EventPeople
  model: Maya.Models.EventPerson
  url: -> "/events/#{@event_id}/event_judges"

class Maya.Collections.EventJudges extends Collections.EventPeople
  model: Maya.Models.EventPerson
  url: -> "/events/#{@event_id}/event_judges"

class Maya.Collections.EventSponsorUsers extends Collections.EventPeople
  model: Maya.Models.EventPerson
  url: -> "/events/#{@event_id}/event_sponsor_users"


# Event Projects
# ==============
Maya.Collections.EventProjects = Backbone.Collection.extend

  params: {}

  setEventId: (event_id) ->
    @event_id = event_id

  search: (term) ->
    @page = 1
    @params['term'] = term
    this.fetch()

  lookingOn: ->
    @page = 1
    @params['looking'] = 'true'
    this.fetch()

  lookingOff: ->
    @page = 1
    delete @params['looking']
    this.fetch()

  url: ->
    "/events/#{@event_id}/event_projects?#{$.param(@params)}"

_.extend(Maya.Collections.EventProjects.prototype, Maya.Utils.PaginatedCollection)


# Schedules
# =========
Maya.Collections.DaySchedules = Backbone.Collection.extend

  url: ->
    "/events/#{@event_id}/day_schedules"

  forEvent: (event_id) ->
    @event_id = event_id

  sorted: ->
    sorted = new Collections.DaySchedules(this.models)
    sorted.comparator = (schedule) ->
      Date.parse(schedule.get("for_day"))
    sorted
