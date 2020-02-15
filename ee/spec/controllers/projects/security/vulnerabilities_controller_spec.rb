# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
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
    allow(Kaminari.config).to receive(:default_per_page).and_return(1)
  end

  describe 'GET #index' do
    render_views

    def show_vulnerability_list(current_user = user)
      sign_in(current_user)
      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    context "when we have vulnerabilities" do
      2.times do
        let_it_be(:vulnerability) { create(:vulnerability, project: project) }
        let_it_be(:finding) { create(:vulnerabilities_occurrence, vulnerability: vulnerability) }
      end

      it 'renders the vulnerability list' do
        show_vulnerability_list

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
        expect(response.body).to have_css(".vulnerabilities-list")
      end

      it 'renders the first vulnerability' do
        show_vulnerability_list

        expect(response.body).to have_css(".js-vulnerability", count: 1)
      end

      it 'renders the pagination' do
        show_vulnerability_list

        expect(response.body).to have_css(".gl-pagination")
      end
    end

    context "when we have no vulnerabilities" do
      it 'renders the empty state' do
        show_vulnerability_list

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to have_css('.empty-state')
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'renders the 404 page' do
        show_vulnerability_list

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    let_it_be(:pipeline) { create(:ci_pipeline, sha: project.commit.id, project: project, user: user) }
    let_it_be(:vulnerability) { create(:vulnerability, project: project) }

    render_views

    def show_vulnerability
      sign_in(user)
      get :show, params: { namespace_id: project.namespace, project_id: project, id: vulnerability.id }
    end

    context "when there's an attached pipeline" do
      let_it_be(:finding) { create(:vulnerabilities_occurrence, vulnerability: vulnerability, pipelines: [pipeline]) }

      it 'renders the vulnerability page' do
        show_vulnerability

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to have_text(vulnerability.title)
      end

      it 'renders the time pipeline ran' do
        show_vulnerability

        expect(response.body).to have_css("#js-pipeline-created")
      end

      it 'renders the solution card' do
        show_vulnerability

        expect(response.body).to have_css("#js-vulnerability-solution")
      end
    end

    context "when there's no attached pipeline" do
      let_it_be(:finding) { create(:vulnerabilities_occurrence, vulnerability: vulnerability) }

      it 'renders the time the vulnerability was created' do
        show_vulnerability

        expect(response.body).to have_css("#js-vulnerability-created")
      end

      it 'renders the solution card' do
        show_vulnerability

        expect(response.body).to have_css("#js-vulnerability-solution")
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'renders the 404 page' do
        show_vulnerability

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
