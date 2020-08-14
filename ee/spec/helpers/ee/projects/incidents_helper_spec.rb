# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsHelper do
  include Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project) }
  let(:project_path) { project.full_path }
  let(:new_issue_path) { new_project_issue_path(project) }
  let(:issue_path) { project_issues_path(project) }

  describe '#incidents_data' do
    let(:expected_incidents_data) do
      {
        'project-path' => project_path,
        'new-issue-path' => new_issue_path,
        'incident-template-name' => 'incident',
        'issue-path' => issue_path
      }
    end

    subject { helper.incidents_data(project) }

    before do
      allow(project).to receive(:feature_available?).with(:status_page).and_return(status_page_feature_available)
    end

    context 'when status page feature is available' do
      let(:status_page_feature_available) { true }

      it { is_expected.to eq(expected_incidents_data.merge('published-available' => 'true')) }
    end

    context 'when status page issue is not available' do
      let(:status_page_feature_available) { false }

      it { is_expected.to eq(expected_incidents_data) }
    end
  end
end
