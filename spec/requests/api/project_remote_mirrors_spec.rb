# frozen_string_literal: true

require 'rails_helper'

describe API::ProjectRemoteMirrors do
  set(:project) { create(:project, :repository, :remote_mirror) }
  set(:user) { project.owner }

  describe 'DELETE /projects/:project_id/remote_mirrors/:id/' do
    let(:remote_mirror) { project.remote_mirrors.first }
    let(:endpoint) { "/projects/#{project.id}/remote_mirrors/#{remote_mirror.id}/" }

    it 'deletes remote mirror' do
      delete api(endpoint, user)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 404 for invalid remote mirror id' do
      delete api("/projects/#{project.id}/remote_mirrors/1234", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Not found')
    end

    it 'returns 404 for unauthorized user' do
      unauthorized_user = create(:user)

      delete api(endpoint, unauthorized_user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Project Not Found')
    end

    it_behaves_like '412 response' do
      let(:request) { api(endpoint, user) }
    end
  end
end
