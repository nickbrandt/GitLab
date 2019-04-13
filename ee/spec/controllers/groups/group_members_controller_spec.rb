require 'spec_helper'

describe Groups::GroupMembersController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, :public, :access_requestable) }
  let(:membership) { create(:group_member, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'POST #override' do
      let(:group) { create(:group_with_ldap_group_link) }

      it 'is successful' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :override_group_member, membership) { true }

        post :override,
             params: {
               group_id: group,
               id: membership,
               group_member: { override: true }
             },
             format: :js

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
