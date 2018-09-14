$(document).ready ->
	ChatView  = Backbone.View.extend
		el: "#chat"
		event_id: null
		parent_id: null
		user_id: null
		slug: null
		template: null
		startReload: 0
		user: null
		user_image: null
		events:
			"click #replyLink" : "displayReply"
			"click #replyChat" : "submitReply"
			"click #postChat" : "postChat"
		
		initialize: ->
			console.log ""

		render: ->
			slug = $("#slugs").val()
			ChatView.slug = slug
			url = "/"+slug+"/live.json"
			$.ajax
				url:url,
				type:"GET",
				dataType: "json"
				success: (payload) ->
					ChatView.user = payload.user
					ChatView.user_image = $("#replyImage").attr("src")
					template = JST["tweet_page"](payload)
					$(".twitter-feed").html(template)
					if ChatView.startReload == 0
						ChatView.liveFeed()

		displayReply: (event) ->
			event.preventDefault()
			topDom = null
			existed = false
			$("a#replyLink").removeClass("clickReply")
			$(event.currentTarget).addClass("clickReply")
			if $(event.currentTarget).data("child") == 0 
				topDom = $(event.currentTarget).parent().parent()
			else
				topDom = $(event.currentTarget).parent().parent().parent().parent()
			for item in topDom[0].children
				for key in item.classList
					if key == "replybox"
						existed = true
			if existed == false
				@event_id = $(event.currentTarget).data("event-id")
				@parent_id = $(event.currentTarget).data("parent-id")
				@user_id = $(event.currentTarget).data("user-id")
				@slug = $(event.currentTarget).data("slug")
				replyBox = JST["reply_box"]({user: ChatView.user, image: ChatView.user_image, event: @event_id, slug: @slug, parent_id:@parent_id})
				if ($(event.currentTarget).data("child") == 0)
					$(event.currentTarget).parent().parent().append(replyBox)
				else
					$(event.currentTarget).parent().parent().parent().parent().append(replyBox)

		submitReply: (event) ->
			event.preventDefault()
			replyContent = $("#replyText").val()
			if replyContent != ""
				url = "/"+@slug+"/receive.json"
				$.ajax
					url:url,
					type: "POST",
					data: {chat:{event_id: @event_id, parent_id: @parent_id, user_id: @user_id, content: replyContent}},
					dataType: "json",
					success: (data) ->
						console.log "sukses lagi cuuy"
						ChatView.render()
					

		postChat: (event) ->
			event.preventDefault()
			chatContent = $("#chatText").val()
			if chatContent != ""
				@event_id = $(event.currentTarget).data("event-id")
				@parent_id = $(event.currentTarget).data("parent-id")
				@user_id = $(event.currentTarget).data("user-id")
				@slug = $(event.currentTarget).data("slug")
				url = "/"+@slug+"/receive.json"
				$.ajax
					url:url,
					type:"POST",
					data: {chat:{event_id: @event_id, parent_id: @parent_id, user_id: @user_id, content: chatContent}},
					dataType: "json"
					success: (data) =>
						$("#chatText").val("")
						ChatView.render()

		liveFeed: =>
			setInterval =>
				console.log "reloading feed"
				ChatView.render()
			, 300000

	if $("#eventMarker").length > 0
		ChatView = new ChatView()
		ChatView.render()