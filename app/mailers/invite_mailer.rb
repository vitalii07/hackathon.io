class InviteMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  include ProfilesHelper

  add_template_helper(ProfilesHelper)
  add_template_helper(Rails.application.routes.url_helpers)

  # Join email email invitation
  def join_event(invite)
    mail_for_event "join", invite
  end

  def judge_event(invite)
    mail_for_event "judge", invite
  end

  def manage_event(invite)
    mail_for_event "manage", invite
  end

  def sponsor_event(invite)
    mail_for_event "sponsor", invite
  end

  def join_project(invite)
    @invite = invite
    mail default_mail_headers("join",  project_from(invite), guest_from(invite))
  end

  def test(from, to, subject)
    mail(to: to, from: from, subject: subject)
  end

  protected

  def mail_for_event(reason, invite)
    @invite = invite
    if invite.guest      
      mail default_mail_headers reason, event_from(invite), guest_from(invite)
    elsif invite.email.present?
      event_from(invite)
      email = invite.email
      # from = "#{@event.title} <support@hackathon.io>"
      from = "support@hackathon.io"
      subject = "Your invitation to #{reason} #{@event.title}"
      mail(to: email, from: from, subject: subject)
    end
  end

  # Generates default mail headers
  # @param [String] reason
  # @param [#title] subject
  # @param [#email, #full_name] to
  def default_mail_headers(reason, subject, to = @guest, from = nil)
    {
      to:      to.email,
      from:    "#{from ? from.title : subject.title} <support@hackathon.io>",
      subject: "Your invitation to #{reason} #{subject.title}"
    }
  end

  def event_from(invite)
    @event = Event.find(invite.purpose_data[:event_id])
  end

  def guest_from(invite)
    @guest = invite.guest
    @name  = @guest.full_name
    @guest
  end

  def project_from(invite)
    @project = Project.find(invite.purpose_data[:project_id])
  end

  #def invite_link(invite)
    #@invite_link = link_to url_for("/i/#{invite.code}"), url_for("/i/#{invite.code}")
  #end
end
