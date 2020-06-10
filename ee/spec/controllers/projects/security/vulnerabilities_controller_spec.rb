# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::VulnerabilitiesController do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
  let_it_be(:user)    { create(:user) }

  before do
    group.add_developer(user)
    stub_licensed_features(security_dashboard: true)
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

      it 'renders the solution card' do
        show_vulnerability

        expect(response.body).to have_css("#js-vulnerability-footer")
      end
    end

    context "when there's no attached pipeline" do
      let_it_be(:finding) { create(:vulnerabilities_occurrence, vulnerability: vulnerability) }

      it 'renders the vulnerability page' do
        show_vulnerability

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to have_text(vulnerability.title)
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

  describe 'GET #discussions' do
    let_it_be(:vulnerability) { create(:vulnerability, project: project, author: user) }
    let_it_be(:discussion_note) { create(:discussion_note_on_vulnerability, noteable: vulnerability, project: vulnerability.project) }

    render_views

    def show_vulnerability_discussion_list
      sign_in(user)
      get :discussions, params: { namespace_id: project.namespace, project_id: project, id: vulnerability }
    end

    it 'renders discussions' do
      show_vulnerability_discussion_list

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('entities/discussions')

      expect(json_response.pluck('id')).to eq([discussion_note.discussion_id])
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'renders the 404 page' do
        show_vulnerability_discussion_list

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
