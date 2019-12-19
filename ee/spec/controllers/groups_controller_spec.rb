# frozen_string_literal: true

require 'spec_helper'

describe GroupsController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }

  describe 'POST #create' do
    context 'authorization' do
      it 'allows an auditor with "can_create_group" set to true to create a group' do
        sign_in(create(:user, :auditor, can_create_group: true))

        expect do
          post :create, params: { group: { name: 'new_group', path: "new_group" } }
        end.to change { Group.count }.by(1)

        expect(response).to have_gitlab_http_status(302)
      end
    end
  end

  describe 'PUT #update' do
    let(:group) { create(:group) }

    context 'when max_pages_size param is specified' do
      let(:params) { { max_pages_size: 100 } }

      let(:request) do
        post :update, params: { id: group.to_param, group: params }
      end

      let(:user) { create(:user) }

      before do
        stub_licensed_features(pages_size_limit: true)
        group.add_owner(user)
        sign_in(user)
      end

      context 'when user is an admin' do
        let(:user) { create(:admin) }

        it 'updates max_pages_size' do
          request

          expect(group.reload.max_pages_size).to eq(100)
        end
      end

      context 'when user is not an admin' do
        it 'does not update max_pages_size' do
          request

          expect(group.reload.max_pages_size).to eq(nil)
        end
      end
    end
  end
end
