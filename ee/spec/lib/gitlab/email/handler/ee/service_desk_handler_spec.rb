# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Handler::EE::ServiceDeskHandler do
  include_context :email_shared_context
  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { email_fixture('emails/service_desk.eml', dir: 'ee') }
  let(:namespace) { create(:namespace, name: "email") }

  context 'service desk is enabled for the project' do
    let(:project) { create(:project, :public, namespace: namespace, path: 'test', service_desk_enabled: true) }

    before do
      allow(Notify).to receive(:service_desk_thank_you_email)
        .with(kind_of(Integer)).and_return(double(deliver_later!: true))

      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).with(project: project).and_return(true)
    end

    context 'when everything is fine' do
      shared_examples 'a new issue request' do
        it 'sends thank you the email and creates issue' do
          setup_attachment

          expect(Notify).to receive(:service_desk_thank_you_email).with(kind_of(Integer))

          expect { receiver.execute }.to change { Issue.count }.by(1)

          new_issue = Issue.last

          expect(new_issue.author).to eql(User.support_bot)
          expect(new_issue.confidential?).to be true
          expect(new_issue.all_references.all).to be_empty
          expect(new_issue.title).to eq("Service Desk (from jake@adventuretime.ooo): The message subject! @all")
          expect(new_issue.description).to eq("Service desk stuff!\n\n```\na = b\n```\n\n![image](uploads/image.png)")
        end
      end

      it_behaves_like 'a new issue request'

      context "creates a new issue with legacy email address" do
        let(:email_raw) { fixture_file('emails/service_desk_legacy.eml', dir: 'ee') }

        it_behaves_like 'a new issue request'
      end
    end

    context 'when email key' do
      let(:mail) { Mail::Message.new(email_raw) }

      it "matches the new format" do
        handler = described_class.new(mail, "h5bp-html5-boilerplate-#{project.project_id}-")

        expect(handler.instance_variable_get(:@project_id).to_i).to eq project.project_id
        expect(handler.can_handle?).to be_truthy
      end

      it "matches the legacy format" do
        handler = described_class.new(mail, "h5bp/html5-boilerplate")

        expect(handler.instance_variable_get(:@project_path)).to eq 'h5bp/html5-boilerplate'
        expect(handler.can_handle?).to be_truthy
      end

      it "doesn't match either format" do
        handler = described_class.new(mail, "h5bp-html5-boilerplate-invalid")

        expect(handler.can_handle?).to be_falsey
      end
    end

    context 'when there is no from address' do
      before do
        allow_any_instance_of(described_class).to receive(:from_address)
          .and_return(nil)
      end

      it "does not send thank you email but create an issue" do
        expect(Notify).not_to receive(:service_desk_thank_you_email)

        expect { receiver.execute }.to change { Issue.count }.by(1)
      end
    end

    context 'when there is a sender address and a from address' do
      let(:email_raw) { email_fixture('emails/service_desk_sender_and_from.eml', dir: 'ee') }

      it 'prefers the from address' do
        setup_attachment

        expect(Notify).to receive(:service_desk_thank_you_email).with(kind_of(Integer))

        expect { receiver.execute }.to change { Issue.count }.by(1)

        new_issue = Issue.last

        expect(new_issue.author).to eql(User.support_bot)
        expect(new_issue.confidential?).to be true
        expect(new_issue.all_references.all).to be_empty
        expect(new_issue.title).to eq("Service Desk (from finn@adventuretime.ooo): The message subject! @all")
        expect(new_issue.description).to eq("Service desk stuff!\n\n```\na = b\n```\n\n![image](uploads/image.png)")
      end
    end

    context 'when license does not support service desk' do
      before do
        allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
      end

      it 'does not create an issue or send email' do
        expect(Notify).not_to receive(:service_desk_thank_you_email)

        expect { receiver.execute rescue nil }.not_to change { Issue.count }
      end
    end

    context 'when the email is forwarded through an alias' do
      let(:email_raw) { email_fixture('emails/service_desk_forwarded.eml', dir: 'ee') }

      it 'sends thank you the email and creates issue' do
        setup_attachment

        expect(Notify).to receive(:service_desk_thank_you_email).with(kind_of(Integer))

        expect { receiver.execute }.to change { Issue.count }.by(1)

        new_issue = Issue.last

        expect(new_issue.author).to eql(User.support_bot)
        expect(new_issue.confidential?).to be true
        expect(new_issue.all_references.all).to be_empty
        expect(new_issue.title).to eq("Service Desk (from jake@adventuretime.ooo): The message subject! @all")
        expect(new_issue.description).to eq("Service desk stuff!\n\n```\na = b\n```\n\n![image](uploads/image.png)")
      end
    end
  end

  context 'service desk is disabled for the project' do
    let(:project) { create(:project, :public, namespace: namespace, path: 'test') }

    it 'bounces the email' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::ProcessingError)
    end

    it "doesn't create an issue" do
      expect { receiver.execute rescue nil }.not_to change { Issue.count }
    end
  end

  def email_fixture(path, dir:)
    fixture_file(path, dir: dir).gsub('project_id', project.project_id.to_s)
  end
end
