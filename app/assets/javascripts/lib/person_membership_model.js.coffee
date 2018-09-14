Maya.Models.PersonMembership = Backbone.Model.extend
  getUser: ->
    new Maya.Models.User(this.get("user"))

  getParentId: (attr) ->
    unless this.get(attr)
      throw new TypeError("attr: #{attr} is not set")
    this.get(attr)
