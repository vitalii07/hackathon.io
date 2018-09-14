require "mandrill"

class Events::EmailsController < ApplicationController
  respond_to :html, :js
  before_filter :require_login
  load_and_authorize_resource :event
  layout 'events'

  def index
    @emails = @event.event_emails
  end

  def new
    @email = @event.event_emails.build
  end

  def show
    @email = @event.event_emails.find(params[:id])
  end

  def edit
    @email = @event.event_emails.find(params[:id])
  end

  def create
    @emails = @event.event_emails
    @email  = @emails.new params[:events_email]
    respond_to do |format|
      begin
        @email.save!
        ScheduledEmailService.new(@email).send_on_schedule
        flash[:info]  = "Email scheduled successfully"
        format.js { render "index" }
      rescue ActiveRecord::RecordInvalid, Mandrill::Error => e
        flash[:error] = e.message
        format.js { render "new" }
      end
    end
  end

  def update
    @emails = @event.event_emails
    @email  = @emails.find(params[:id])
    @email.attributes = params[:events_email]
    respond_to do |format|
      begin
        changed = @email.changes.present?
        @email.save!
        ScheduledEmailService.new(@email).send_on_schedule if changed
        flash[:info]  = "Email updated successfully"
        format.js { render "index" }
      rescue ActiveRecord::RecordInvalid, Mandrill::Error => e
        flash[:error] = e.message
        format.js { render "edit" }
      end
    end
  end

  def destroy
    @emails = @event.event_emails
    @email = @emails.find(params[:id])

    if @email.destroy
      ScheduledEmailService.new(@email).unschedule
      flash[:info] = "Email unscheduled successfully"
      @emails.reload
    else
      flash[:info] = "Email cannot be unscheduled"
    end

    respond_to do |format|
      format.js   { render "index" }
    end
  end
end
