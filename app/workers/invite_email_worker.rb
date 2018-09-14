class InviteEmailWorker
  @queue = :invite_emails

  def self.perform(invitation_id)
    invite = Invitation.find(invitation_id)
    InviteMailer.send(invite.purpose, invite).deliver
    invite.email_sent_at = Time.zone.now
    invite.save
  end
end
