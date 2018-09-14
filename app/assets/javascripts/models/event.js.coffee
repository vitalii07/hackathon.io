# Event Model
# ===========
#
# Main Event Model
Maya.Models.Event = Backbone.Model.extend
  urlRoot: '/events'

# EventPeople
# ===========
#
# Main EventPerson Class. All other event person types will extend from this class
class Maya.Models.EventPerson extends Models.PersonMembership

  getEventId: ->
    this.getParentId('event_id')

  eventUrl: ->
    "/events/#{this.getEventId()}"

class  Maya.Models.EventAdministrator extends Maya.Models.EventPerson
  urlRoot: ->
    "#{this.eventUrl()}/event_admins"
class Maya.Models.EventJudge extends Maya.Models.EventPerson
  url: ->
    "#{this.eventUrl()}/event_judges"

class Maya.Models.EventParticipant extends Maya.Models.EventPerson
  url: ->
    "#{this.eventUrl()}/event_participants"

class Maya.Models.EventSponsorUser extends Maya.Models.EventPerson
  url: ->
    "#{this.eventUrl()}/event_sponsor_users"


# Submissions (Bulk)
# ==================
# Stores Multiple Submissions for a an Event
Maya.Models.SubmissionBulk = Backbone.Model.extend

  setEventId: (event_id) ->
    this.set('event_id', event_id)

  url: ->
    throw new ArgumentError("event_id is not set") unless this.get('event_id')?
    "/events/#{this.get('event_id')}/submissions_bulk"

# Votes
# =====
Maya.Models.Vote = Backbone.Model.extend
  urlRoot: '/votes'

# Schedules
# =========
Maya.Models.DaySchedule = Backbone.Model.extend

  urlRoot: ->
    "/events/#{this.get('event_id')}/day_schedules"

