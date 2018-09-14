# UI Widgets used across Hackathon.IO

class Maya.Widgets.RemoteModal

  constructor: (event, xhr, status)  ->
    $('<div/>', class: 'new-modal-loaded-content')
    .appendTo(document)
    .reveal()
    .html(xhr.responseText)
    .find('form')
    .on 'ajax:beforeSend', (event,xhr, settings) ->
      $('.load-in-modal .modal')
      .css('opacity', 0.8)
      .spin()
    .on 'ajax:complete', (event, xhr, status) ->
      $('.new-modal-loaded-content')
      .modal('hide')
      .remove()
    .find('.cancel')
    .on "click", (event) ->
      $('.new-modal-loaded-content')
        .modal('hide')
        .remove()
      false
  # Loads a remote url in a Modal


Maya.initialize_widgets = ->
  $('a[data-remote-modal]').on 'ajax:complete', Maya.Widgets.RemoteModal
  $('.load-in-modal').on 'ajax:complete', Maya.Widgets.RemoteModal
