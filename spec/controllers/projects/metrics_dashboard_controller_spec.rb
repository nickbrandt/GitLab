# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MetricsDashboardController do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, name: 'main-dos').tap { |u| project.add_maintainer(u) } }
  let_it_be(:reporter) { create(:user, name: 'repo-dos').tap { |u| project.add_reporter(u) } }

  let!(:default_environment) { create(:environment, name: 'default', project: project) }
  let!(:environment_2) { create(:environment, name: 'staging', project: project) }
  let(:user) { maintainer }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'without environment' do
      it 'uses default environment' do
        get :show, params: metrics_dashboard_params(dashboard_path: 'some/path.yml')

        expect(assigns(:environment)).to eq(default_environment)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with environment specified' do
      it 'assigns specified environment' do
        get :show, params: metrics_dashboard_params(dashboard_path: 'some/path.yml', environment: environment_2.id)

        expect(assigns(:environment)).to eq(environment_2)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'permissions' do
      before do
        allow(controller).to receive(:can?).and_return true
      end

      it 'checks :metrics_dashboard_ability' do
        expect(controller).to receive(:can?).with(anything, :metrics_dashboard, anything)

        get :show, params: metrics_dashboard_params
      end
    end

    context 'with anonymous user and public dashboard visibility' do
      let(:user) { create(:user) }
      let(:project) do
        create(:project, :public, metrics_dashboard_access_level: 'enabled')
      end

      it 'returns success' do
        get :show, params: metrics_dashboard_params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  def metrics_dashboard_params(opts = {})
    opts.reverse_merge({
      namespace_id: project.namespace,
      project_id: project
    })
  end
end
