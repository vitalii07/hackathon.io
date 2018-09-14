require "spec_helper"

describe Notifier do

  describe "message" do

    before do
      @message = create(:message)
      @conversation = @message.conversation
      @conversation.created_by = @message.sender
    end

    let(:user) { FactoryGirl.create(:user) }
    let(:mail) { Notifier.message_email(@message, user) }

    it "renders email" do
      expect(mail.to).to eql [ user.email ]
      expect(mail.subject).to eql "#{@message.sender.full_name} sent you a message"
      #expect(mail.reply_to).to eql "#{@message.email_key}@messages.#{ENV['HOST_NAME']}"
      mail.body.should include @message.content
    end
  end
end
