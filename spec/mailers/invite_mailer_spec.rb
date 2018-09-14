require "spec_helper"

describe InviteMailer do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:event_user) { event.event_users.create(:user_id => user.id) }
  let(:invite) { event_user.create_invitation }
  let(:invite_url) { "http://#{ENV['HOST_NAME']}/i/#{invite.code}" }

  describe "join_event" do
    let(:mail) { InviteMailer.join_event(invite) }
    it "renders email" do
      expect(mail.subject).to start_with "Your invitation to join"
      mail.to.should eq [invite.guest.email]
      mail.body.should include "Hi"
      mail.body.should include invite_url
    end
  end

  describe "judge_event" do
    let(:event_user) { event.event_users.create(:user_id => user.id, :can_judge => true) }
    let(:mail) { InviteMailer.judge_event(invite) }

    it "renders the email" do
      mail.subject.should start_with "Your invitation to judge"
      mail.to.should eq [invite.guest.email]
      mail.body.should include "Hi"
      mail.body.should include invite_url
    end
  end

  describe "manage_event" do
    let(:event_user) { event.event_users.create(:user_id => user.id, :can_manage => true) }
    let(:mail) { InviteMailer.manage_event(invite) }

    it "renders the headers" do
      mail.subject.should start_with "Your invitation to manage"
      mail.to.should eq [invite.guest.email]
      mail.body.should include "Hi"
      mail.body.should include invite_url
    end
  end

  describe "join_project" do
    let(:invite) { project.memberships.create(:user_id => user.id).create_invitation }
    let(:mail) { InviteMailer.join_project(invite) }
    let(:project) { create(:project) }

    it "renders the headers" do
      mail.subject.should start_with "Your invitation to join"
      mail.to.should eq([invite.guest.email])
      mail.body.should include "Hi"
      mail.body.should include @invite_url
    end
  end
end
