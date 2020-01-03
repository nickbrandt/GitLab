# frozen_string_literal: true

require 'spec_helper'

describe 'Self-Monitoring project requests' do
  let(:admin) { create(:admin) }

  describe 'POST #create_self_monitoring_project' do
    let(:worker_class) { SelfMonitoringProjectCreateWorker }

    subject { post create_self_monitoring_project_admin_application_settings_path }

    it_behaves_like 'not accessible to non-admin users'

    context 'with admin user' do
      before do
        login_as(admin)
      end

      context 'with feature flag disabled' do
        it_behaves_like 'not accessible if feature flag is disabled'
      end

      context 'with feature flag enabled' do
        let(:status_api) { status_create_self_monitoring_project_admin_application_settings_path }

        it_behaves_like 'triggers async worker, returns sidekiq job_id with response accepted'
      end
    end
  end

  describe 'GET #status_create_self_monitoring_project' do
    let(:worker_class) { SelfMonitoringProjectCreateWorker }
    let(:job_id) { 'job_id' }

    subject do
      get status_create_self_monitoring_project_admin_application_settings_path,
        params: { job_id: job_id }
    end

    it_behaves_like 'not accessible to non-admin users'

    context 'with admin user' do
      before do
        login_as(admin)
      end

      context 'with feature flag disabled' do
        it_behaves_like 'not accessible if feature flag is disabled'
      end

      context 'with feature flag enabled' do
        it_behaves_like 'calls .status, handles invalid job_id, and different status values'

        context 'when status returns completed' do
          let(:status) { { status: :completed, output: { status: :success } } }
          let(:project) { build(:project) }

          before do
            allow(worker_class).to receive(:status).and_return(status)

            stub_application_setting(instance_administration_project_id: 2)
            stub_application_setting(instance_administration_project: project)
          end

          it 'returns output' do
            subject

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:success)
              expect(json_response).to eq(
                'status' => 'success',
                'project_id' => 2,
                'project_full_path' => project.full_path
              )
            end
          end
        end
      end
    end
  end
end
