# frozen_string_literal: true

require 'spec_helper'

describe Groups::EpicLinksController, :postgresql do
  let(:group) { create(:group, :public) }
  let(:parent_epic) { create(:epic, group: group) }
  let(:epic1) { create(:epic, group: group) }
  let(:epic2) { create(:epic, group: group) }
  let(:user)  { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples 'unlicensed epics action' do
    before do
      stub_licensed_features(epics: false)
      group.add_developer(user)

      subject
    end

    it 'returns 400 status' do
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET #index' do
    before do
      epic1.update(parent: parent_epic)
    end

    subject { get :index, params: { group_id: group, epic_id: parent_epic.to_param } }

    it_behaves_like 'unlicensed epics action'

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
        group.add_developer(user)

        subject
      end

      it 'returns the correct JSON response' do
        list_service_response = EpicLinks::ListService.new(parent_epic, user).execute

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq(list_service_response.as_json)
      end
    end
  end

  describe 'POST #create' do
    subject do
      reference = [epic1.to_reference(full: true)]

      post :create, params: { group_id: group, epic_id: parent_epic.to_param, issuable_references: reference }
    end

    it_behaves_like 'unlicensed epics action'

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to create requested association' do
        before do
          group.add_developer(user)
        end

        it 'returns correct response for the correct issue reference' do
          subject
          list_service_response = EpicLinks::ListService.new(parent_epic, user).execute

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to eq('message' => nil, 'issuables' => list_service_response.as_json)
        end

        it 'updates a parent for the referenced epic' do
          expect { subject }.to change { epic1.reload.parent }.from(nil).to(parent_epic)
        end
      end

      context 'when user does not have permissions to create requested association' do
        it 'returns 403 status' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end

        it 'does not update parent attribute' do
          expect { subject }.not_to change { epic1.reload.parent }.from(nil)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      epic1.update(parent: parent_epic)
    end

    subject { delete :destroy, params: { group_id: group, epic_id: parent_epic.to_param, id: epic1.id } }

    it_behaves_like 'unlicensed epics action'

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to update the parent epic' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response.status).to eq(200)
        end

        it 'destroys the link' do
          expect { subject }.to change { epic1.reload.parent }.from(parent_epic).to(nil)
        end
      end

      context 'when user does not have permissions to update the parent epic' do
        it 'returns status 404' do
          subject

          expect(response.status).to eq(403)
        end

        it 'does not destroy the link' do
          expect { subject }.not_to change { epic1.reload.parent }.from(parent_epic)
        end
      end

      context 'when the epic does not have any parent' do
        it 'returns status 404' do
          delete :destroy, params: { group_id: group, epic_id: parent_epic.to_param, id: epic2.id }

          expect(response.status).to eq(403)
        end
      end
    end
  end
end
