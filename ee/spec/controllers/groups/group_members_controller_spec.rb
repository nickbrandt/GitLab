# frozen_string_literal: true

require 'spec_helper'

describe Groups::GroupMembersController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, :public) }
  let(:membership) { create(:group_member, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'POST #create' do
    it 'creates an audit event' do
      expect do
        post :create, params: { group_id: group,
                                user_ids: user.id,
                                access_level: Gitlab::Access::GUEST }
      end.to change(AuditEvent, :count).by(1)
    end
  end

  describe 'DELETE #leave' do
    context 'when member is not an owner' do
      it 'creates an audit event' do
        developer = create(:user)
        group.add_developer(developer)
        sign_in(developer)

        expect { delete :leave, params: { group_id: group } }.to change(AuditEvent, :count).by(1)
      end
    end

    context 'when member is an owner' do
      it 'does not create an audit event' do
        expect { delete :leave, params: { group_id: group } }.not_to change(AuditEvent, :count)
      end
    end

    context 'when member requested access' do
      it 'creates an audit event' do
        requester = create(:user)
        group.request_access(requester)
        sign_in(requester)

        expect { delete :leave, params: { group_id: group } }.to change(AuditEvent, :count).by(1)
      end
    end
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

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
