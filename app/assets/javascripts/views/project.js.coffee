class Maya.Views.Project extends Backbone.View
  el: '#project-profile'
  events: {
    'click .edit-demo'     : 'editDemo'
    'click .save-demo'     : 'saveDemo'

    'click .edit-project'  : 'editProject'
    'click .save-project'  : 'saveProject'

    'click a.add-member'    : 'addMember'
    'click a.send-member'   : 'sendMember'
    'click .remove-member' : 'deleteMember'

    # 'click .member'        : 'redirectToProfile'

    'keyup .member-email'  : 'checkSubmit'
  }

  demoShowTemplate: JST['projects/demo_preview']
  demoEditTemplate: JST['projects/demo_edit']

  initialize: (options) ->
    @model = new Maya.Models.Project({id: options.id})
    @model.on 'sync', @render
    # @stackEditor = new Maya.Views.stack(model: @model)
    @model.fetch()

    @head = @$('#head')
    @demoBody = @$('#demo .body')

  # redirectToProfile: (event) ->
  #   window.location = "/#{$(event.currentTarget).data('slug')}" if $(event.currentTarget).data('slug')
  #   false

  editDemo: ->
    @$('.edit-demo')
      .removeClass('edit-demo')
      .addClass('save-demo')
      .html('<i class="icon icon-save"></i> Save Demo')
    @demoBody.html @demoEditTemplate(video_url: @model.get('video_url'))
    false

  saveDemo: ->
    input = @$('.video_url_input')
    if input.get(0).checkValidity()
      @$('.save-demo')
        .removeClass('save-demo')
        .addClass('edit-demo')
        .html('<i class="icon icon-edit"></i> Edit Demo')
      input.removeClass('invalid')
      @model.set('video_url', input.val()).save()
    else
      @$('.video_url_input').addClass('invalid')
    false

  addMember: (e)->
    e.preventDefault()
    button = @$('.add-member')
    button.hide()
    button.after("<input id=\"inputAddress\" style=\"position:relative;left:10px\" type=\"email\" placeholder=\"email@address.com\" class=\"member-email three columns\" style=\"float: right; height: 28px; margin-right: 10px;\"/>
                  <br/><a id=\"submitButton\" style=\"position:relative;left:10px\" class=\"send-member big-red-button\" href=\"#\"><i class=\"icon icon-save\"></i> Invite</a>")
    false

  checkSubmit: (event) => @sendMember() if 13 == event.keyCode

  sendMember: (e) ->
    e.preventDefault()
    input = $('#inputAddress')
    if input.get(0).checkValidity()
      email = input.val()
      @model.addMember(email, success: =>
        #doing a refresh instead
        @$('#inputAddress').remove()
        @$('#submitButton').remove()
        @$('.add-member').show()
        window.location = window.location
        # window.location.reload


        # button.removeClass('send-member')
        #       .addClass('add-member')
        #       .html('<i class="icon icon-plus-sign-alt"></i> Add member')

        # input.remove()
      )
    false

  deleteMember: (event) ->
    tile = $(@$(event.currentTarget).parent())
    id = tile.data('id')
    @model.deleteMember(id, success: =>
      if Maya.current_user.id == id
        window.location = window.location
      else
        $(tile.parent()).remove()
    )
    false

  render: =>
    @renderMemberEditor()
    # @renderDemo()
    @

  renderMemberEditor: =>
    if Maya.current_user.id in (this.model.members().map (user) -> user.get('id'))
      @$('.team-wrapper .round-button').each ->
        $(this).append '<i class="remove-member icon icon-remove-sign"/>'

  renderDemo: =>
    @demoBody.html @demoShowTemplate(video_url: @model.get('video_url'))