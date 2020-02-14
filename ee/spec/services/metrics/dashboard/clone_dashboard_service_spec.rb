# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::CloneDashboardService, :use_clean_rails_memory_store_caching do
  STAGES = ::Gitlab::Metrics::Dashboard::Stages

  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }
  set(:environment) { create(:environment, project: project) }

  describe '#execute' do
    subject(:service_call) { described_class.new(project, user, params).execute }

    context 'with rights to push to the repository' do
      before do
        project.add_maintainer(user)
      end

      context 'valid parameters' do
        let(:commit_message) { 'test' }
        let(:branch) { "#{Time.current.to_i}_dashboard_new_branch" }
        let(:file_name) { 'custom_dashboard.yml' }
        let(:file_content_hash) { YAML.safe_load(File.read(dashboard)) }
        let(:params) do
          {
            dashboard: dashboard,
            file_name: file_name,
            commit_message: commit_message,
            branch: branch
          }
        end

        it_behaves_like 'valid dashboard cloning process', ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH, [STAGES::CommonMetricsInserter, STAGES::ProjectMetricsInserter, STAGES::Sorter]
        it_behaves_like 'valid dashboard cloning process', ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH, [STAGES::CommonMetricsInserter, STAGES::Sorter]
      end
    end
  end
end
