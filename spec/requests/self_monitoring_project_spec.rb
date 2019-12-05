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
        it 'returns sidekiq job_id of expected length' do
          subject

          job_id = json_response['job_id']

          aggregate_failures do
            expect(job_id).to be_present
            expect(job_id.length).to be <= Admin::ApplicationSettingsController::PARAM_JOB_ID_MAX_SIZE
          end
        end

        it 'triggers async worker' do
          expect(worker_class).to receive(:perform_async)

          subject
        end

        it 'returns accepted response' do
          subject

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:accepted)
            expect(json_response.keys).to contain_exactly('job_id', 'monitor_status')
            expect(json_response).to include(
              'monitor_status' => status_create_self_monitoring_project_admin_application_settings_path
            )
          end
        end

        it 'returns job_id' do
          fake_job_id = 'b5b28910d97563e58c2fe55f'
          expect(worker_class).to receive(:perform_async).and_return(fake_job_id)

          subject
          response_job_id = json_response['job_id']

          expect(response_job_id).to eq fake_job_id
        end
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
        it 'calls .status' do
          expect(worker_class).to receive(:status).with(job_id).and_call_original

          subject
        end

        it 'sets polling header' do
          expect(::Gitlab::PollingInterval).to receive(:set_header)

          subject
        end

        context 'with invalid job_id' do
          it_behaves_like 'handles missing or invalid job_id', nil
          it_behaves_like 'handles missing or invalid job_id', job_id: nil
          it_behaves_like 'handles missing or invalid job_id', job_id: [2]

          it 'returns bad_request if job_id too long' do
            get status_create_self_monitoring_project_admin_application_settings_path,
              params: { job_id: 'a' * 51 }

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq('message' => 'Parameter "job_id" cannot ' \
                "exceed length of #{Admin::ApplicationSettingsController::PARAM_JOB_ID_MAX_SIZE}")
            end
          end
        end

        context 'different status values' do
          before do
            allow(worker_class).to receive(:status).and_return(status)
          end

          context 'when status returns in_progress' do
            let(:status) { { status: :in_progress } }

            it 'returns status accepted' do
              subject

              aggregate_failures do
                expect(response).to have_gitlab_http_status(:accepted)
                expect(json_response).to eq('status' => 'in_progress')
              end
            end
          end

          context 'when status returns unknown' do
            let(:status) { { status: :unknown, message: 'message' } }

            it 'returns accepted' do
              subject

              aggregate_failures do
                expect(response).to have_gitlab_http_status(:accepted)
                expect(json_response).to eq(
                  'status' => 'unknown',
                  'message' => 'message'
                )
              end
            end
          end

          context 'when status returns completed' do
            let(:status) { { status: :completed, output: { status: :success } } }
            let(:project) { build(:project) }

            before do
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

          context 'when unexpected status is returned' do
            let(:status) { { status: :unexpected_status } }

            it 'raises error' do
              expect { subject }.to raise_error(
                StandardError, 'SelfMonitoringProjectCreateWorker#status returned ' \
                  'unknown status "unexpected_status"'
              )
            end

            context 'in production' do
              before do
                stub_rails_env('production')
              end

              it 'returns internal_server_error' do
                subject

                aggregate_failures do
                  expect(response).to have_gitlab_http_status(:internal_server_error)
                  expect(json_response).to eq(
                    'message' => 'SelfMonitoringProjectCreateWorker#status returned ' \
                      'unknown status "unexpected_status"'
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
