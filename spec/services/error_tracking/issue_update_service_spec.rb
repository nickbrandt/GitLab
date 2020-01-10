# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::IssueUpdateService do
  include_context 'sentry error tracking context'

  let(:arguments) { { issue_id: 1234, status: 'resolved' } }

  subject { described_class.new(project, user, arguments) }

  describe '#execute' do
    context 'with authorized user' do
      context 'when update_issue returns success' do
        let(:update_issue_response) { { updated: true } }

        before do
          expect(error_tracking_setting)
            .to receive(:update_issue).and_return(update_issue_response)
        end

        it 'returns the response' do
          expect(result).to eq(update_issue_response.merge(status: :success))
        end

        it 'updates any related issue' do
          expect(subject).to receive(:update_related_issue)

          result
        end

        context 'related issue and resolving' do
          let(:issue) { create(:issue, project: project) }
          let(:sentry_issue) { create(:sentry_issue, issue: issue) }
          let(:arguments) { { issue_id: sentry_issue.sentry_issue_identifier, status: 'resolved' } }

          let(:issue_close_service) { spy(:issue_close_service) }

          before do
            allow_any_instance_of(SentryIssuesFinder)
              .to receive(:find_by_identifier)
              .and_return(sentry_issue)
          end

          after do
            result
          end

          it 'closes the issue' do
            close_service = spy(:close_service)
            expect(Issues::CloseService)
              .to receive(:new)
              .and_return(close_service)

            expect(close_service)
              .to receive(:execute)
              .with(issue, system_note: false)
              .and_return(issue)
          end

          it 'creates a system note' do
            expect(SystemNoteService).to receive(:close_after_error_tracking_resolve)
          end
        end
      end

      include_examples 'error tracking service sentry error handling', :update_issue
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end
