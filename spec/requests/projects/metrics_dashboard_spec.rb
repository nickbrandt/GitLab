# frozen_string_literal: true

require 'spec_helper'

describe 'metrics dashboard page' do
  # Further tests can be found at metrics_dashboard_controller_spec.rb
  let(:project) { create(:project) }
  let!(:environment) { create(:environment, project: project) }
  let!(:environment2) { create(:environment, project: project) }
  let(:user) { project.owner }

  before do
    project.add_developer(user)
    login_as(user)
  end

  describe 'GET /:namespace/:project/-/d' do
    it 'returns 200' do
      send_request
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns environment' do
      send_request
      expect(assigns(:environment).id).to eq(environment.id)
    end
  end

  describe 'GET /:namespace/:project/-/d?environment=:environment.id' do
    it 'returns 200' do
      send_request(environment: environment2.id)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns query param environment' do
      send_request(environment: environment2.id)
      expect(assigns(:environment).id).to eq(environment2.id)
    end

    context 'when query param environment does not exist' do
      it 'responds with 404' do
        send_request(environment: 99)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /:namespace/:project/-d/:dashboard_path' do
    let(:dashboard_path) { '.gitlab/dashboards/dashboard_path.yml' }

    it 'returns 200' do
      send_request(dashboard: dashboard_path)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns environment0' do
      send_request(dashboard: dashboard_path)
      expect(assigns(:environment).id).to eq(environment.id)
    end
  end

  describe 'GET :/namespace/:project/-d/:dashboard_path?environment=:environment.id' do
    let(:dashboard_path) { '.gitlab/dashboards/dashboard_path.yml' }

    it 'returns 200' do
      send_request(dahboard: dashboard_path, environment: environment.id)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns query param environment' do
      send_request(dashboard: dashboard_path, environment: environment2.id)
      expect(assigns(:environment).id).to eq(environment2.id)
    end

    context 'when query param environment does not exist' do
      it 'responds with 404' do
        send_request(dashboard: dashboard_path, environment: 99)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def send_request(params = {})
    get namespace_project_metrics_dashboard_page_path(namespace_id: project.namespace, project_id: project, **params)
  end
end
