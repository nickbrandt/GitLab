# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::CloneDashboardService, :use_clean_rails_memory_store_caching do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }
  set(:environment) { create(:environment, project: project) }

  describe '#execute' do
    context 'with rights to push to the repository' do
      before do
        project.add_maintainer(user)
      end

      context 'valid parameters' do
        let(:commit_message) { 'test' }
        let(:branch) { "#{Time.current.to_i}_dashboard_new_branch" }
        let(:file_name) { 'custom_dashboard.yml' }

        [::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH, ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH].each do |dashboard_template|
          context "dashboard template #{dashboard_template}" do
            let(:dashboard) { dashboard_template }
            let(:params) do
              {
                dashboard: dashboard,
                file_name: file_name,
                commit_message: commit_message,
                branch: branch
              }
            end

            it 'delegates commit creation to Files::CreateService', :aggregate_failures do
              dashboard_attrs = {
                commit_message: commit_message,
                branch_name: branch,
                start_branch: 'master',
                encoding: 'text',
                file_path: '.gitlab/dashboards/custom_dashboard.yml',
                file_content: File.read(dashboard)
              }

              service_instance = instance_double(::Files::CreateService)
              expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
              expect(service_instance).to receive(:execute).and_return(status: :success)

              described_class.new(project, user, params).execute
            end
          end
        end
      end
    end
  end
end
