# frozen_string_literal: true

require 'spec_helper'

describe Projects::EnvironmentsController do
  include KubernetesHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project) }

  set(:environment) do
    create(:environment, name: 'production', project: project)
  end

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET index' do
    context 'when requesting JSON response for folders' do
      before do
        allow_any_instance_of(EE::Environment).to receive(:has_terminals?).and_return(true)
        allow_any_instance_of(EE::Environment).to receive(:rollout_status).and_return(kube_deployment_rollout_status)

        create(:environment, project: project,
                             name: 'staging/review-1',
                             state: :available)

        create(:environment, project: project,
                             name: 'staging/review-2',
                             state: :available)

        create(:environment, project: project,
                             name: 'staging/review-3',
                             state: :stopped)
      end

      let(:environments) { json_response['environments'] }

      context 'when requesting available environments scope' do
        before do
          stub_licensed_features(deploy_board: true)

          get :index, params: environment_params(format: :json, nested: true, scope: :available)
        end

        it 'responds with matching schema' do
          expect(response).to match_response_schema('environments', dir: 'ee')
        end

        it 'responds with a payload describing available environments' do
          expect(environments.count).to eq 2
          expect(environments.first['name']).to eq 'production'
          expect(environments.first['latest']['rollout_status']).to be_present
          expect(environments.second['name']).to eq 'staging'
          expect(environments.second['size']).to eq 2
          expect(environments.second['latest']['name']).to eq 'staging/review-2'
          expect(environments.second['latest']['rollout_status']).to be_present
        end
      end

      context 'when license does not has the GitLab_DeployBoard add-on' do
        before do
          stub_licensed_features(deploy_board: false)

          get :index, params: environment_params(format: :json, nested: true)
        end

        it 'does not return the rollout_status_path attribute' do
          expect(environments.first['latest']['rollout_status']).not_to be_present
          expect(environments.second['latest']['rollout_status']).not_to be_present
        end
      end
    end
  end

  describe 'GET #logs_redirect' do
    let(:project) { create(:project) }

    it 'redirects to environment if it exists' do
      environment = create(:environment, name: 'production', project: project)

      get :logs_redirect, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to redirect_to(logs_project_environment_path(project, environment))
    end

    it 'renders empty logs page if no environment exists' do
      get :logs_redirect, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to be_ok
      expect(response).to render_template 'empty_logs'
    end
  end

  describe 'GET logs' do
    let(:pod_name) { "foo" }

    before do
      stub_licensed_features(pod_logs: true)
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(pod_logs: false)
      end

      it 'renders forbidden' do
        get :logs, params: environment_params(pod_name: pod_name)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when licensed' do
      it 'renders logs template' do
        get :logs, params: environment_params(pod_name: pod_name)

        expect(response).to be_ok
        expect(response).to render_template 'logs'
      end
    end
  end

  describe 'GET k8s_pod_logs' do
    let(:pod_name) { "foo" }
    let(:container) { 'container-1' }

    let(:service_result) do
      {
        status: :success,
        logs: ['Log 1', 'Log 2', 'Log 3'],
        message: 'message',
        pods: [pod_name],
        pod_name: pod_name,
        container_name: container
      }
    end

    before do
      stub_licensed_features(pod_logs: true)

      allow_any_instance_of(PodLogsService).to receive(:execute).and_return(service_result)
    end

    shared_examples 'resource not found' do |message|
      it 'returns 400', :aggregate_failures do
        get :k8s_pod_logs, params: environment_params(pod_name: pod_name, format: :json)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(message)
        expect(json_response['pods']).to match_array([pod_name])
        expect(json_response['pod_name']).to eq(pod_name)
        expect(json_response['container_name']).to eq(container)
      end
    end

    it 'returns the logs for a specific pod', :aggregate_failures do
      get :k8s_pod_logs, params: environment_params(pod_name: pod_name, format: :json)

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response["logs"]).to match_array(["Log 1", "Log 2", "Log 3"])
      expect(json_response["pods"]).to match_array([pod_name])
      expect(json_response['message']).to eq(service_result[:message])
      expect(json_response['pod_name']).to eq(pod_name)
      expect(json_response['container_name']).to eq(container)
    end

    it 'registers a usage of the endpoint' do
      expect(::Gitlab::UsageCounters::PodLogs).to receive(:increment).with(project.id)

      get :k8s_pod_logs, params: environment_params(pod_name: pod_name, format: :json)
    end

    context 'when kubernetes API returns error' do
      let(:service_result) do
        {
          status: :error,
          message: 'Kubernetes API returned status code: 400',
          pods: [pod_name],
          pod_name: pod_name,
          container_name: container
        }
      end

      it 'returns bad request' do
        get :k8s_pod_logs, params: environment_params(pod_name: pod_name, format: :json)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response["logs"]).to eq(nil)
        expect(json_response["pods"]).to match_array([pod_name])
        expect(json_response["message"]).to eq('Kubernetes API returned status code: 400')
        expect(json_response['pod_name']).to eq(pod_name)
        expect(json_response['container_name']).to eq(container)
      end
    end

    context 'when pod does not exist' do
      let(:service_result) do
        {
          status: :error,
          message: 'Pod not found',
          pods: [pod_name],
          pod_name: pod_name,
          container_name: container
        }
      end

      it_behaves_like 'resource not found', 'Pod not found'
    end

    context 'when service returns error without pods, pod_name, container_name' do
      let(:service_result) do
        {
          status: :error,
          message: 'No deployment platform'
        }
      end

      it 'returns the error without pods, pod_name and container_name' do
        get :k8s_pod_logs, params: environment_params(pod_name: pod_name, format: :json)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('No deployment platform')
        expect(json_response.keys).to contain_exactly('message', 'status')
      end
    end

    context 'when service returns status processing' do
      let(:service_result) { { status: :processing } }

      it 'renders accepted' do
        get :k8s_pod_logs, params: environment_params(pod_name: pod_name, format: :json)

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end
  end

  describe '#GET terminal' do
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    before do
      allow(License).to receive(:feature_available?).and_call_original
      allow(License).to receive(:feature_available?).with(:protected_environments).and_return(true)
    end

    context 'when environment is protected' do
      context 'when user does not have access to it' do
        before do
          protected_environment

          get :terminal, params: environment_params
        end

        it 'responds with access denied' do
          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when user has access to it' do
        before do
          protected_environment.deploy_access_levels.create(user: user)

          get :terminal, params: environment_params
        end

        it 'is successful' do
          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'when environment is not protected' do
      it 'is successful' do
        get :terminal, params: environment_params

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe 'POST #cancel_auto_stop' do
    subject { post :cancel_auto_stop, params: params }

    let(:params) { environment_params }

    context 'when environment is set as auto-stop' do
      let(:environment) { create(:environment, :will_auto_stop, name: 'staging', project: project) }

      it_behaves_like 'successful response for #cancel_auto_stop'

      context 'when the environment is protected' do
        before do
          stub_licensed_features(protected_environments: true)
          create(:protected_environment, name: 'staging', project: project)
        end

        it 'shows NOT Found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       id: environment.id)
  end
end
