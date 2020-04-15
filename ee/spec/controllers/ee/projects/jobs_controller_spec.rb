# frozen_string_literal: true

require 'spec_helper'

describe Projects::JobsController do
  let(:owner) { create(:owner) }
  let(:admin) { create(:admin) }
  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:project) { create(:project, :private, :repository, namespace: owner.namespace) }
  let(:pipeline) { create(:ci_pipeline, project: project, source: :webide, config_source: :webide_source, user: user) }
  let(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }
  let(:user) { maintainer }
  let(:extra_params) { { id: job.id } }

  before do
    stub_licensed_features(web_ide_terminal: true)
    stub_feature_flags(build_service_proxy: true)
    allow(job).to receive(:has_terminal?).and_return(true)

    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)

    sign_in(user)
  end

  shared_examples 'proxy access rights' do
    before do
      allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)

      make_request
    end

    context 'with admin' do
      let(:user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when admin mode is disabled' do
        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with owner' do
      let(:user) { owner }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with maintainer' do
      let(:user) { maintainer }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with developer' do
      let(:user) { developer }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with guest' do
      let(:user) { guest }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with non member' do
      let(:user) { create(:user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'when pipeline is not from a webide source' do
    context 'with admin' do
      let(:user) { admin }
      let(:pipeline) { create(:ci_pipeline, project: project, source: :chat, user: user) }

      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
        make_request
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'validates workhorse signature' do
    context 'with valid workhorse signature' do
      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
      end

      context 'and valid id' do
        it 'returns the proxy data for the service running in the job' do
          make_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq(expected_data)
        end
      end

      context 'and invalid id' do
        let(:extra_params) { { id: non_existing_record_id } }

        it 'returns 404' do
          make_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with invalid workhorse signature' do
      it 'aborts with an exception' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(JWT::DecodeError)

        expect { make_request }.to raise_error(JWT::DecodeError)
      end
    end
  end

  shared_examples 'feature flag "build_service_proxy" is disabled' do
    let(:user) { admin }

    it 'returns 404' do
      allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
      stub_feature_flags(build_service_proxy: false)

      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #show', :clean_gitlab_redis_shared_state do
    context 'when requesting JSON' do
      context 'with shared runner that has quota' do
        let(:project) { create(:project, :private, shared_runners_enabled: true) }
        let(:merge_request) { create(:merge_request, source_project: project) }
        let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
        let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

        before do
          project.add_developer(user)
          sign_in(user)

          allow_next_instance_of(Ci::Build) do |instance|
            allow(instance).to receive(:merge_request).and_return(merge_request)
          end

          stub_application_setting(shared_runners_minutes: 2)

          get_show(id: job.id, format: :json)
        end

        it 'exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']['quota']['used']).to eq 0
          expect(json_response['runners']['quota']['limit']).to eq 2
        end
      end

      context 'with shared runner quota exceeded' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }
        let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

        before do
          project.add_developer(user)
          sign_in(user)

          get_show(id: job.id, format: :json)
        end

        it 'exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']['quota']['used']).to eq 1000
          expect(json_response['runners']['quota']['limit']).to eq 500
        end
      end

      context 'when shared runner has no quota' do
        let(:project) { create(:project, :private, shared_runners_enabled: true) }
        let(:merge_request) { create(:merge_request, source_project: project) }
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
        let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

        before do
          project.add_developer(user)
          sign_in(user)

          allow_next_instance_of(Ci::Build) do |instance|
            allow(instance).to receive(:merge_request).and_return(merge_request)
          end

          stub_application_setting(shared_runners_minutes: 0)

          get_show(id: job.id, format: :json)
        end

        it 'does not exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']).not_to have_key('quota')
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :public, shared_runners_enabled: true) }
        let(:merge_request) { create(:merge_request, source_project: project) }
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
        let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

        before do
          project.add_developer(user)
          sign_in(user)

          allow_next_instance_of(Ci::Build) do |instance|
            allow(instance).to receive(:merge_request).and_return(merge_request)
          end

          stub_application_setting(shared_runners_minutes: 2)

          get_show(id: job.id, format: :json)
        end

        it 'does not exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']).not_to have_key('quota')
        end
      end
    end

    private

    def get_show(**extra_params)
      params = {
          namespace_id: project.namespace.to_param,
          project_id: project
      }

      get :show, params: params.merge(extra_params)
    end
  end

  describe 'GET #proxy_websocket_authorize' do
    let(:path) { :proxy_websocket_authorize }
    let(:render_method) { :channel_websocket }
    let(:expected_data) do
      {
        'Channel' => {
          'Subprotocols' => ["terminal.gitlab.com"],
          'Url' => 'wss://localhost/proxy/build/default_port/',
          'Header' => {
            'Authorization' => [nil]
          },
          'MaxSessionTime' => nil,
          'CAPem' => nil
        }
      }.to_json
    end

    it_behaves_like 'proxy access rights'
    it_behaves_like 'when pipeline is not from a webide source'
    it_behaves_like 'validates workhorse signature'
    it_behaves_like 'feature flag "build_service_proxy" is disabled'

    it 'converts the url scheme into wss' do
      allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)

      expect(job.runner_session_url).to start_with('https://')
      expect(Gitlab::Workhorse).to receive(:channel_websocket).with(a_hash_including(url: "wss://localhost/proxy/build/default_port/"))

      make_request
    end
  end

  def make_request
    params = {
      namespace_id: project.namespace.to_param,
      project_id: project
    }

    get path, params: params.merge(extra_params)
  end
end
