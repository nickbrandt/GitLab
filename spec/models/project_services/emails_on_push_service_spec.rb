# frozen_string_literal: true

require 'spec_helper'

describe EmailsOnPushService do
  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  context 'project emails' do
    let(:push_data) { { object_kind: 'push' } }
    let(:project)   { create(:project, :repository) }
    let(:service)   { create(:emails_on_push_service, project: project) }
    let(:recipients) { 'test@gitlab.com' }

    before do
      subject.recipients = recipients
    end

    shared_examples 'sending email' do |branches_to_be_notified|
      before do
        subject.branches_to_be_notified = branches_to_be_notified
      end

      it 'sends email' do
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        service.execute(push_data)
      end
    end

    shared_examples 'not sending email' do |branches_to_be_notified|
      before do
        subject.branches_to_be_notified = branches_to_be_notified
      end

      it 'does not send email' do
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        service.execute(push_data)
      end
    end

    context 'when emails are disabled on the project' do
      it 'does not send emails' do
        expect(project).to receive(:emails_disabled?).and_return(true)
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        service.execute(push_data)
      end
    end

    context 'when emails are enabled on the project' do
      before do
        expect(project).to receive(:emails_disabled?).and_return(true)
      end

      context 'pushing to the default branch' do
        let(:push_data) { { object_kind: 'push', object_attributes: { ref: project.default_branch } } }

        context 'when configured to send email on pushes to any branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end

        context 'when configured to send email on pushes to default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'when configured to send email on pushes to protected branches only' do
          it_behaves_like 'not sending email', branches_to_be_notified: "protected"
        end

        context 'when configured to send email on pushes to default and protected branches only' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end
      end

      context 'pushing to a protected branch' do
        before do
          create(:protected_branch, project: project, name: 'a-protected-branch')
        end

        let(:push_data) { { object_kind: 'push', object_attributes: { ref: 'a-protected-branch' } } }

        context 'when configured to send email on pushes to any branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end

        context 'when configured to send email on pushes to default branch' do
          it_behaves_like 'not sending email', branches_to_be_notified: "default"
        end

        context 'when configured to send email on pushes to protected branches only' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'when configured to send email on pushes to default and protected branches only' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end
      end

      context 'pushing to a random branch' do
        let(:push_data) { { object_kind: 'push', object_attributes: { ref: 'a-random-branch' } } }

        context 'when configured to send email on pushes to any branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end

        context 'when configured to send email on pushes to default branch' do
          it_behaves_like 'not sending email', branches_to_be_notified: "default"
        end

        context 'when configured to send email on pushes to protected branches only' do
          it_behaves_like 'not sending email', branches_to_be_notified: "protected"
        end

        context 'when configured to send email on pushes to default and protected branches only' do
          it_behaves_like 'not sending email', branches_to_be_notified: "default_and_protected"
        end
      end
    end
  end
end
