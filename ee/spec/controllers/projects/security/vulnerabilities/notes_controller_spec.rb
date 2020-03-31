# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::Vulnerabilities::NotesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:vulnerability) { create(:vulnerability, project: project) }
  let_it_be(:note) { create(:note, noteable: vulnerability, project: project) }

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { project }

    let(:security_dashboard_action) do
      get :index, params: { namespace_id: project.namespace, project_id: project, vulnerability_id: vulnerability }
    end
  end

  before do
    stub_licensed_features(security_dashboard: true)
  end

  describe 'GET index' do
    subject(:view_all_notes) do
      get :index, params: { namespace_id: project.namespace, project_id: project, vulnerability_id: vulnerability }
    end

    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'responds with array of notes' do
      view_all_notes

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('vulnerability_notes', dir: 'ee')

      expect(json_response['notes']).to be_an Array
      expect(json_response['notes'].pluck('id')).to eq([note.id.to_s])
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'renders the 404 page' do
        view_all_notes

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
