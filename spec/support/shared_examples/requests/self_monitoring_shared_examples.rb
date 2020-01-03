# frozen_string_literal: true

RSpec.shared_examples 'not accessible if feature flag is disabled' do
  before do
    stub_feature_flags(self_monitoring_project: false)
  end

  it 'returns not_implemented' do
    subject

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:not_implemented)
      expect(json_response).to eq(
        'message' => _('Self-monitoring is not enabled on this GitLab server, contact your administrator.'),
        'documentation_url' => help_page_path('administration/monitoring/gitlab_instance_administration_project/index')
      )
    end
  end
end

RSpec.shared_examples 'handles missing or invalid job_id' do |job_id_param|
  it "returns bad_request for #{job_id_param}" do
    get status_create_self_monitoring_project_admin_application_settings_path, params: job_id_param

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq('message' => '"job_id" must be an alphanumeric value')
    end
  end
end

RSpec.shared_examples 'not accessible to non-admin users' do
  context 'with unauthenticated user' do
    it 'redirects to signin page' do
      subject

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'with authenticated non-admin user' do
    before do
      login_as(create(:user))
    end

    it 'returns status not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

# Requires subject and worker_class and status_api to be defined
#   let(:worker_class) { SelfMonitoringProjectCreateWorker }
#   let(:status_api) { status_create_self_monitoring_project_admin_application_settings_path }
#   subject { post create_self_monitoring_project_admin_application_settings_path }
RSpec.shared_examples 'triggers async worker, returns sidekiq job_id with response accepted' do
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
        'monitor_status' => status_api
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

# Requires worker_class, job_id and subject to be defined
#   let(:worker_class) { SelfMonitoringProjectCreateWorker }
#   let(:job_id) { 'job_id' }
#   subject do
#     get status_create_self_monitoring_project_admin_application_settings_path,
#       params: { job_id: job_id }
#   end
RSpec.shared_examples 'calls .status, handles invalid job_id, and different status values' do
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

    context 'when unexpected status is returned' do
      let(:status) { { status: :unexpected_status } }

      it 'raises error' do
        expect { subject }.to raise_error(
          StandardError, "#{worker_class}#status returned " \
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
              'message' => "#{worker_class}#status returned " \
                'unknown status "unexpected_status"'
            )
          end
        end
      end
    end
  end
end
