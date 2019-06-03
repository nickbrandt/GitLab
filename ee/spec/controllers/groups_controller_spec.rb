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
end
