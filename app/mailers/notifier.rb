class Notifier < ActionMailer::Base
  default from: "Hackathon.IO <support@hackathon.io>"

  def password_recovery_mail(recipient)
    @recipient = recipient
    mail(:to => recipient.email, :subject => "Password Assistance")
  end

  def claim_message_to_admin(claim, admin)
    @message = claim.message
    @user = claim.user.full_name
    @event = claim.event.title
    recipients = admin
    recipients_email = recipients.collect(&:email)
    mail(:to => recipients_email, :subject => "New Claim Message")
  end

  def confirmation_mail_to_new_email(recipient)
    @recipient = recipient
    @recipient_email = @recipient.temp_email
    mail(:to => @recipient_email, :subject => "Confirm new email address")
  end

  def confirmation_mail_to_existing_email(recipient)
    @recipient = recipient
    @recipient_email = @recipient.email
    mail(:to => @recipient_email, :subject => "hackathon has received a request to change your account's email address")
  end

  def message_email(msg, user)
    @message = msg
    @conversation = @message.conversation
    @user = user
    #@message.email_sent_at = Time.now
    #@message.save(:validate => false)
    mail to:       @user.email,
         subject:  @message.subject,
         reply_to: "#{@message.email_key}@#{ENV['MESSAGES_DOMAIN']}"
  end

  def confirm_new_email(email, user)
    @email = email
    @user = user
    mail(to: @email.email, subject: "[hackathon.io] Please confirm your email address")
  end
  
  def send_report(sponsor_id, s3_key)
    sponsor = Organization.find(sponsor_id)
    @user = sponsor.members.first
    s3 = AWS::S3.new
    if Rails.env.production?
      bucket_name = 'hackathon.io.reports'
    elsif Rails.env.testing?
      bucket_name = 'testing.hackathon.io.reports'
    elsif Rails.env.development?
      bucket_name = 'dev.hackathon.io.reports'      
    end
     
    bucket = s3.buckets[bucket_name]
    obj = bucket.objects[s3_key]
        
    file_name = Pathname.new(s3_key).basename.to_s
    attachments[file_name] =  obj.read
    
    mail to:       @user.email,
         subject:  "API Report"
  end
end
