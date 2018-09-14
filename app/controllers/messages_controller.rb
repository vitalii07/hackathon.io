class MessagesController < ApplicationController
  before_filter :require_login
  respond_to :js, :html, :json

  def show
    respond_with @message = current_user.messages.find(params[:id])
  end

  def new
    @message = Message.new
    @message.receivers_ids = receivers_from_params.map(&:id)
    session[:return_to_url] = request.referer
    respond_to do |format|
      format.js
      format.json { render :json => @message }
      format.html
    end
  end

  # Send a message (email) to the recievers
  def create
    @conversation = Conversation.find(params[:conversation_id])
    if @conversation.messages.create(sender: current_user,
                                    content: params[:message][:content])
      redirect_to @conversation
    else
      flash[:error] = "A problem occured"
      redirect_to @conversation
    end
    #respond_to do |format|
    #  format.js   { render json: @message }
    #  format.html { redirect_back_or_to :back }
    #end
  end

  protected

  def receivers_from_params
    @receivers ||= params[:message][:receivers_ids].reject(&:blank?).map { |id| User.find(id) }
  end

  # Send emails to multiple receipients
  def send_to_multiple(receiver_ids, pars)
    @receivers = receiver_ids.reject(&:blank?).map { |id| User.find(id) }
    @messages = @receivers.map do |user|
      Message.create sender:   current_user,
                     receiver: user,
                     content:  pars[:content]
    end
    flash[:info]  = "Your message has been sent"
  end

  # Sends message to single participant
  def send_to_single(pars)
    @message = Message.new(pars)
    @message.sender = current_user
    if @message.save
      flash[:info]  = "Your message has been sent to #{@message.receiver.full_name}"
    else
      flash[:error] = "Your message could not be sent to #{@message.receiver.full_name}"
    end
  end

  #returns true if labeled spam message
  def check_for_spamming
    #first check if it is a new conversation
    if !params[:message][:conversation_id]
      if current_user.conversations.recent.count < 5 #max 5 new convos/hour
        false
      else
        true
      end
    else
      false #limit_replies
    end
  end

  #checks for spam within a convo, can't mass message a person
  def limit_replies
    conversation = Conversation.find(params[:message][:conversation_id])
    if conversation.messages.count > 4
      spam_filter = true
      conversation.messages[-5..-1].each do |m|
        if m.sender_id != current_user.id
          spam_filter = false
          break
        end
      end
      spam_filter
    else
      false
    end
  end

end
