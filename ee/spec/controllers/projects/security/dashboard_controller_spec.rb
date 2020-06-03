# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DashboardController do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
  let_it_be(:user)    { create(:user) }

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { project }

    let(:security_dashboard_action) do
      get :index, params: { namespace_id: project.namespace, project_id: project }
    end
  end

  before do
    group.add_developer(user)
    stub_licensed_features(security_dashboard: true)
  end

  describe 'GET #index' do
    let(:pipeline) { create(:ci_pipeline, sha: project.commit.id, project: project, user: user) }

    render_views

    def show_security_dashboard(current_user = user)
      sign_in(current_user)
      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    context 'when uses legacy reports syntax' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline, name: 'sast')
      end

      it 'returns the latest pipeline with security reports for project' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
        expect(response.body).to have_css("div#js-security-report-app[data-has-pipeline-data]")
      end
    end

    context 'when uses new reports syntax' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline)
      end

      it 'returns the latest pipeline with security reports for project' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
        expect(response.body).to have_css("div#js-security-report-app[data-has-pipeline-data]")
      end
    end

    context 'when there is no matching pipeline' do
      it 'renders empty state' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
        expect(response.body).not_to have_css("div#js-security-report-app[data-has-pipeline-data]")
      end
    end
  end
end
