require 'spec_helper'

describe Projects::Security::DashboardController do
  set(:group)   { create(:group) }
  set(:project) { create(:project, :repository, :public, namespace: group) }
  set(:user)    { create(:user) }

  before do
    group.add_developer(user)
  end

  describe 'GET #show' do
    let(:pipeline) { create(:ci_pipeline_without_jobs, sha: project.commit.id, project: project, user: user) }

    render_views

    def show_security_dashboard(current_user = user)
      sign_in(current_user)
      get :show, params: { namespace_id: project.namespace, project_id: project }
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
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

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns 404' do
        show_security_dashboard

        expect(response).to have_gitlab_http_status(404)
        expect(response).to render_template('errors/not_found')
      end
    end

    context 'with unauthorized user for security dashboard' do
      let(:guest) { create(:user) }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'returns a not found 404 response' do
        group.add_guest(guest)

        show_security_dashboard guest

        expect(response).to have_gitlab_http_status(404)
        expect(response).to render_template('errors/not_found')
      end
    end
  end
end
