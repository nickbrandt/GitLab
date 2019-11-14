# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::DashboardController do
  set(:group)   { create(:group) }
  set(:project) { create(:project, :repository, :public, namespace: group) }
  set(:user)    { create(:user) }

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { project }

    let(:security_dashboard_action) do
      get :show, params: { namespace_id: project.namespace, project_id: project }
    end
  end

  before do
    group.add_developer(user)
  end

  describe 'GET #show' do
    let(:pipeline) { create(:ci_pipeline, sha: project.commit.id, project: project, user: user) }

    render_views

    def show_security_dashboard(current_user = user)
      stub_licensed_features(security_dashboard: true)
      sign_in(current_user)
      get :show, params: { namespace_id: project.namespace, project_id: project }
    end

    context 'when uses legacy reports syntax' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline, name: 'sast')
      end

      it 'returns the latest pipeline with security reports for project' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to have_css("div#js-security-report-app[data-has-pipeline-data=true]")
      end
    end

    context 'when uses new reports syntax' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline)
      end

      it 'returns the latest pipeline with security reports for project' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to have_css("div#js-security-report-app[data-has-pipeline-data=true]")
      end
    end

    context 'when there is no matching pipeline' do
      it 'renders empty state' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to have_css("div#js-security-report-app[data-has-pipeline-data=false]")
      end
    end
  end
end
