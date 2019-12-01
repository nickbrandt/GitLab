# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Handler::EE::ServiceDeskHandler do
  include_context :email_shared_context

  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { email_fixture('emails/service_desk.eml', dir: 'ee') }
  let_it_be(:namespace) { create(:namespace, name: "email") }
  let(:expected_description) { "Service desk stuff!\n\n```\na = b\n```\n\n![image](uploads/image.png)" }

  context 'service desk is enabled for the project' do
    let_it_be(:project) { create(:project, :repository, :public, namespace: namespace, path: 'test', service_desk_enabled: true) }

    before do
      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).with(project: project).and_return(true)
    end

    shared_examples 'a new issue request' do
      before do
        setup_attachment
      end

      it 'creates a new issue' do
        expect { receiver.execute }.to change { Issue.count }.by(1)

        new_issue = Issue.last

        expect(new_issue.author).to eql(User.support_bot)
        expect(new_issue.confidential?).to be true
        expect(new_issue.all_references.all).to be_empty
        expect(new_issue.title).to eq("Service Desk (from jake@adventuretime.ooo): The message subject! @all")
        expect(new_issue.description).to eq(expected_description.strip)
      end

      it 'sends thank you email' do
        expect { receiver.execute }.to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'when everything is fine' do
      it_behaves_like 'a new issue request'

      context 'with legacy incoming email address' do
        let(:email_raw) { fixture_file('emails/service_desk_legacy.eml', dir: 'ee') }

        it_behaves_like 'a new issue request'
      end

      context 'when using issue templates' do
        let_it_be(:user) { create(:user) }

        before do
          setup_attachment
        end

        context 'and template is present' do
          it 'appends template text to issue description' do
            template_path = '.gitlab/issue_templates/service_desk.md'
            project.repository.create_file(user, template_path, 'text from template', message: 'message', branch_name: 'master')
            ServiceDeskSetting.update_template_key_for(project: project, issue_template_key: 'service_desk')

            receiver.execute

            issue_description = Issue.last.description
            expect(issue_description).to include(expected_description)
            expect(issue_description.lines.last).to eq('text from template')
          end
        end

        context 'and template cannot be found' do
          before do
            service = ServiceDeskSetting.new(project_id: project.id, issue_template_key: 'unknown')
            service.save(validate: false)
          end

          it 'does not append template text to issue description' do
            receiver.execute

            new_issue = Issue.last

            expect(new_issue.description).to eq(expected_description.strip)
          end

          it 'creates support bot note on issue' do
            receiver.execute

            note = Note.last

            expect(note.note).to include("WARNING: The template file unknown.md used for service desk issues is empty or could not be found.")
            expect(note.author).to eq(User.support_bot)
          end

          it 'does not send warning note email' do
            ActionMailer::Base.deliveries = []

            perform_enqueued_jobs do
              expect { receiver.execute }.to change { ActionMailer::Base.deliveries.size }.by(1)
            end

            # Only sends created issue email
            expect(ActionMailer::Base.deliveries.last.text_part.body).to include("Thank you for your support request!")
          end
        end
      end
    end

    describe '#can_handle?' do
      let(:mail) { Mail::Message.new(email_raw) }

      it 'handles the new email key format' do
        handler = described_class.new(mail, "h5bp-html5-boilerplate-#{project.project_id}-issue-")

        expect(handler.instance_variable_get(:@project_id).to_i).to eq project.project_id
        expect(handler.can_handle?).to be_truthy
      end

      it 'handles the legacy email key format' do
        handler = described_class.new(mail, "h5bp/html5-boilerplate")

        expect(handler.instance_variable_get(:@project_path)).to eq 'h5bp/html5-boilerplate'
        expect(handler.can_handle?).to be_truthy
      end

      it "doesn't handle invalid email key" do
        handler = described_class.new(mail, "h5bp-html5-boilerplate-invalid")

        expect(handler.can_handle?).to be_falsey
      end
    end

    context 'when there is no from address' do
      before do
        allow_any_instance_of(described_class).to receive(:from_address)
          .and_return(nil)
      end

      it "creates a new issue" do
        expect { receiver.execute }.to change { Issue.count }.by(1)
      end

      it 'does not send thank you email' do
        expect { receiver.execute }.not_to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'when there is a sender address and a from address' do
      let(:email_raw) { email_fixture('emails/service_desk_sender_and_from.eml', dir: 'ee') }

      it 'prefers the from address' do
        setup_attachment

        expect { receiver.execute }.to change { Issue.count }.by(1)

        new_issue = Issue.last

        expect(new_issue.service_desk_reply_to).to eq('finn@adventuretime.ooo')
      end
    end

    context 'when license does not support service desk' do
      before do
        allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
      end

      it 'does not create an issue' do
        expect { receiver.execute rescue nil }.not_to change { Issue.count }
      end

      it 'does not send thank you email' do
        expect { receiver.execute rescue nil }.not_to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'when the email is forwarded through an alias' do
      let(:email_raw) { email_fixture('emails/service_desk_forwarded.eml', dir: 'ee') }

      it_behaves_like 'a new issue request'
    end

    context 'when the email is forwarded' do
      let(:email_raw) { email_fixture('emails/service_desk_forwarded_new_issue.eml', dir: 'ee') }

      it_behaves_like 'a new issue request' do
        let(:expected_description) do
          <<~EOF
            Service desk stuff!

            ---------- Forwarded message ---------
            From: Jake the Dog <jake@adventuretime.ooo>
            To: <jake@adventuretime.ooo>


            forwarded content

            ![image](uploads/image.png)
          EOF
        end
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
