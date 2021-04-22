# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ExternalIssueTracker::Menu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:jira_issues_integration_active) { false }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, jira_issues_integration: jira_issues_integration_active) }

  subject { described_class.new(context) }

  describe '#render?' do
    before do
      expect(subject).to receive(:external_issue_tracker).and_return(external_issue_tracker).at_least(1)
    end

    context 'when active external issue tracker' do
      let(:external_issue_tracker) { build(:custom_issue_tracker_service, project: project) }

      context 'is present' do
        it 'returns true' do
          expect(subject.render?).to be_truthy
        end
      end

      context 'is not present' do
        let(:external_issue_tracker) { nil }

        it 'returns false' do
          expect(subject.render?).to be_falsey
        end
      end
    end

    context 'when external issue tracker is a Jira one' do
      let(:external_issue_tracker) { build(:jira_service, project: project) }

      context 'when Jira issues integration is disabled' do
        it 'returns true' do
          expect(subject.render?).to be_truthy
        end
      end

      context 'when Jira issues integration is enabled' do
        let(:jira_issues_integration_active) { true }

        it 'returns false' do
          expect(subject.render?).to be_falsey
        end
      end
    end
  end
end
