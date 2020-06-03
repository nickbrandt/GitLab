# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::CloneDashboardService, :use_clean_rails_memory_store_caching do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }

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
        let(:stages) { ::Gitlab::Metrics::Dashboard::Stages }

        it_behaves_like 'valid dashboard cloning process', ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH,
          [
            ::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
            ::Gitlab::Metrics::Dashboard::Stages::CustomMetricsInserter,
            ::Gitlab::Metrics::Dashboard::Stages::Sorter
          ]

        it_behaves_like 'valid dashboard cloning process', ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH,
          [
            ::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
            ::Gitlab::Metrics::Dashboard::Stages::Sorter
          ]
      end
    end
  end
end
