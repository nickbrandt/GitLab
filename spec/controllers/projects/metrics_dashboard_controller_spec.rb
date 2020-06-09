# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::MetricsDashboardController do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, name: 'main-dos').tap { |u| project.add_maintainer(u) } }

  let(:user) { maintainer }

  let!(:environment) { create(:environment, name: 'production', project: project) }
  let!(:second_environment) { create(:environment, name: 'staging', project: project) }

  before do
    sign_in(user)
  end

  describe 'GET d' do
    it 'responds with status code 200' do
      get :metrics_dashboard_page, params: params

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns default environment' do
      get :metrics_dashboard_page, params: params

      expect(assigns(:environment).id).to eq(environment.id)
    end

    context 'with valid environment parameter' do
      let(:valid_environment_params) { params(environment: second_environment.id) }

      it 'responds with status code 200' do
        get :metrics_dashboard_page, params: valid_environment_params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'assigns param environment' do
        get :metrics_dashboard_page, params: valid_environment_params

        expect(assigns(:environment).id).to eq(second_environment.id)
      end
    end

    context 'with invalid environment parameter' do
      let(:invalid_environment_params) { params(environment: 9999)}

      it 'responds with 404' do
        get :metrics_dashboard_page, params: invalid_environment_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with custom dashboard path' do
      it 'responds with status code 200' do
        get :metrics_dashboard_page, params: params(dashboard_path: 'custom_dashboard_path.yml')

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  def params(opts = {})
    opts.reverse_merge({
      namespace_id: project.namespace,
      project_id: project
    })
  end
end
