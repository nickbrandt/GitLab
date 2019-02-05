# frozen_string_literal: true

require 'spec_helper'

describe API::EpicLinks do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:epic) { create(:epic, group: group) }

  shared_examples 'user does not have access' do
    it 'returns 403 when epics feature is disabled' do
      group.add_developer(user)

      get api(url, user)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'returns 401 unauthorized error for non authenticated user' do
      get api(url)

      expect(response).to have_gitlab_http_status(401)
    end

    it 'returns 404 not found error for a user without permissions to see the group' do
      group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      get api(url, user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /groups/:id/epics/:epic_iid/epics' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics" }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      let!(:child_epic1) { create(:epic, group: group, parent: epic) }
      let!(:child_epic2) { create(:epic, group: group, parent: epic) }

      it 'returns 200 status' do
        get api(url, user)

        epics = JSON.parse(response.body)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
        expect(epics.map { |epic| epic["id"] }).to match_array([child_epic1.id, child_epic2.id])
      end
    end
  end

  describe 'POST /groups/:id/epics/:epic_iid/epics' do
    let(:child_epic) { create(:epic, group: group) }
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics" }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user is guest' do
        it 'returns 403' do
          group.add_guest(user)

          post api("#{url}/#{child_epic.id}", user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user is developer' do
        it 'returns 201 status' do
          group.add_developer(user)

          post api("#{url}/#{child_epic.id}", user)

          expect(response).to have_gitlab_http_status(201)
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          expect(epic.reload.children).to include(child_epic)
        end
      end

      context 'when target epic cannot be read' do
        let(:other_group) { create(:group, :private) }
        let(:child_epic) { create(:epic, group: other_group) }

        it 'returns 404 status' do
          group.add_developer(user)

          post api(url, user), params: { child_epic_id: child_epic.id }

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'DELETE /groups/:id/epics/:epic_iid/epics' do
    let!(:child_epic) { create(:epic, group: group, parent: epic)}
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics" }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user is guest' do
        it 'returns 403' do
          group.add_guest(user)

          delete api("#{url}/#{child_epic.id}", user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user is developer' do
        it 'returns 200 status' do
          group.add_developer(user)

          delete api("#{url}/#{child_epic.id}", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          expect(epic.reload.children).not_to include(child_epic)
        end
      end
    end
  end
end
