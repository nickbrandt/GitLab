# frozen_string_literal: true

require 'spec_helper'

describe API::Users do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  context 'extended audit events' do
    describe "PUT /users/:id" do
      it "creates audit event when updating user with new password" do
        stub_licensed_features(extended_audit_events: true)

        put api("/users/#{user.id}", admin), params: { password: '12345678' }

        expect(AuditEvent.count).to eq(1)
      end
    end
  end

  context 'shared_runners_minutes_limit' do
    describe "PUT /users/:id" do
      context 'when user is an admin' do
        it "updates shared_runners_minutes_limit" do
          expect do
            put api("/users/#{user.id}", admin), params: { shared_runners_minutes_limit: 133 }
          end.to change { user.reload.shared_runners_minutes_limit }
                   .from(nil).to(133)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['shared_runners_minutes_limit']).to eq(133)
        end
      end

      context 'when user is not an admin' do
        it "cannot update their own shared_runners_minutes_limit" do
          expect do
            put api("/users/#{user.id}", user), params: { shared_runners_minutes_limit: 133 }
          end.not_to change { user.reload.shared_runners_minutes_limit }

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end
  end

  context 'with group SAML' do
    let(:saml_provider) { create(:saml_provider) }

    it 'creates user with new identity' do
      post api("/users", admin), params: attributes_for(:user, provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['identities'].first['extern_uid']).to eq('67890')
      expect(json_response['identities'].first['provider']).to eq('group_saml')
      expect(json_response['identities'].first['saml_provider_id']).to eq(saml_provider.id)
    end

    it 'creates user with new identity without sending reset password email' do
      post api("/users", admin), params: attributes_for(:user, reset_password: false, provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id)

      expect(response).to have_gitlab_http_status(201)

      new_user = User.find(json_response['id'])
      expect(new_user.recently_sent_password_reset?).to eq(false)
    end

    it 'updates user with new identity' do
      put api("/users/#{user.id}", admin), params: { provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['identities'].first['extern_uid']).to eq('67890')
      expect(json_response['identities'].first['provider']).to eq('group_saml')
      expect(json_response['identities'].first['saml_provider_id']).to eq(saml_provider.id)
    end

    it 'fails to update user with nonexistent identity' do
      put api("/users/#{user.id}", admin), params: { provider: 'group_saml', extern_uid: '67890', group_id_for_saml: 15 }
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq({ "identities.saml_provider_id" => ["can't be blank"] })
    end

    it 'fails to update user with nonexistent provider' do
      put api("/users/#{user.id}", admin), params: { provider: nil, extern_uid: '67890', group_id_for_saml: saml_provider.group.id }
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq({ "identities.provider" => ["can't be blank"] })
    end
  end
end
