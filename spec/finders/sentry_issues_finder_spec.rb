# frozen_string_literal: true

require 'spec_helper'

describe SentryIssuesFinder do
  let(:user)       { create(:user) }
  let(:project)    { create(:project, :repository) }
  let(:issue) { create(:issue, project: project) }
  let(:sentry_issue) { create(:sentry_issue, issue: issue) }

  let(:finder) { described_class.new(project, user) }

  describe '#find_by_identifier' do
    let(:identifier) { sentry_issue.sentry_issue_identifier }

    subject { finder.find_by_identifier(identifier) }

    context 'when the user is not part of the project' do
      it 'returns no sentry issues' do
        is_expected.to eq(nil)
      end
    end

    context 'when the user is a project developer' do
      before do
        project.add_developer(user)
      end

      it 'returns the matching sentry issue' do
        expect(subject).to eq(sentry_issue)
      end

      context 'when identifier is incorrect is false' do
        let(:identifier) { 1234 }

        it 'does not return a sentry issue' do
          expect(subject).to eq(nil)
        end
      end

      context 'when accessing another projects identifier' do
        let(:second_project) { create(:project) }
        let(:second_issue) { create(:issue, project: second_project) }
        let(:second_sentry_issue) { create(:sentry_issue, issue: second_issue) }

        let(:identifier) { second_sentry_issue.sentry_issue_identifier }

        it 'does not return a sentry issue' do
          expect(subject).to eq(nil)
        end
      end
    end
  end
end
