# frozen_string_literal: true
require 'spec_helper'

describe Projects::AutocompleteSourcesController do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  set(:group2) { create(:group) }
  set(:project) { create(:project, :public, group: group) }
  set(:epic) { create(:epic, group: group) }
  set(:epic2) { create(:epic, group: group2) }

  before do
    sign_in(user)
  end

  context 'when epics feture is disabled' do
    it 'returns 404 status' do
      get :epics, namespace_id: project.namespace, project_id: project

      expect(response).to have_gitlab_http_status(404)
    end
  end

  context 'when epics feture is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context '#epics' do
      it 'returns the correct response' do
        get :epics, namespace_id: project.namespace, project_id: project

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.count).to eq(1)
        expect(json_response.first).to include(
          'iid' => epic.iid, 'title' => epic.title
        )
      end
    end
  end
end
