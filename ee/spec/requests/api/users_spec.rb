# frozen_string_literal: true

require 'spec_helper'

describe API::Users do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  context 'updating name' do
    shared_examples_for 'admin can update the name of a user' do
      it 'updates the user with new name' do
        put api("/users/#{user.id}", admin), params: { name: 'New Name' }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq('New Name')
      end
    end

    context 'when `disable_name_update_for_users` feature is available' do
      before do
        stub_licensed_features(disable_name_update_for_users: true)
      end

      context 'when the ability to update their name is disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: true)
        end

        it_behaves_like 'admin can update the name of a user'
      end

      context 'when the ability to update their name is not disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: false)
        end

        it_behaves_like 'admin can update the name of a user'
      end
    end

    context 'when `disable_name_update_for_users` feature is not available' do
      before do
        stub_licensed_features(disable_name_update_for_users: false)
      end

      it_behaves_like 'admin can update the name of a user'
    end
  end

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

  context 'admin notes' do
    let(:admin) { create(:admin, note: '2019-10-06 | 2FA added | user requested | www.gitlab.com') }
    let(:user) { create(:user, note: '2018-11-05 | 2FA removed | user requested | www.gitlab.com') }

    describe 'GET /users/:id' do
      context 'when unauthenticated' do
        it 'does not contain the note of the user' do
          get api("/users/#{user.id}")

          expect(json_response).not_to have_key('note')
        end
      end

      context 'when authenticated' do
        context 'as an admin' do
          it 'contains the note of the user' do
            get api("/users/#{user.id}", admin)

            expect(json_response).to have_key('note')
            expect(json_response['note']).to eq(user.note)
          end
        end

        context 'as a regular user' do
          it 'does not contain the note of the user' do
            get api("/users/#{user.id}", user)

            expect(json_response).not_to have_key('note')
          end
        end
      end
    end

    describe "PUT /users/:id" do
      context 'when user is an admin' do
        it "updates note of the user" do
          new_note = '2019-07-07 | Email changed | user requested | www.gitlab.com'

          expect do
            put api("/users/#{user.id}", admin), params: { note: new_note }
          end.to change { user.reload.note }
                   .from('2018-11-05 | 2FA removed | user requested | www.gitlab.com')
                   .to(new_note)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['note']).to eq(new_note)
        end
      end

      context 'when user is not an admin' do
        it "cannot update their own note" do
          expect do
            put api("/users/#{user.id}", user), params: { note: 'new note' }
          end.not_to change { user.reload.note }

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    describe 'GET /users/' do
      context 'when unauthenticated' do
        it "does not contain the note of users" do
          get api("/users"), params: { username: user.username }

          expect(json_response.first).not_to have_key('note')
        end
      end

      context 'when authenticated' do
        context 'as a regular user' do
          it 'does not contain the note of users' do
            get api("/users", user), params: { username: user.username }

            expect(json_response.first).not_to have_key('note')
          end
        end

        context 'as an admin' do
          it 'contains the note of users' do
            get api("/users", admin), params: { username: user.username }

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response.first).to have_key('note')
            expect(json_response.first['note']).to eq '2018-11-05 | 2FA removed | user requested | www.gitlab.com'
          end
        end
      end
    end

    describe 'GET /user' do
      context 'when authenticated' do
        context 'as an admin' do
          context 'accesses their own profile' do
            it 'contains the note of the user' do
              get api("/user", admin)

              expect(json_response).to have_key('note')
              expect(json_response['note']).to eq(admin.note)
            end
          end

          context 'sudo' do
            let(:admin_personal_access_token) { create(:personal_access_token, user: admin, scopes: %w[api sudo]).token }

            context 'accesses the profile of another regular user' do
              it 'does not contain the note of the user' do
                get api("/user?private_token=#{admin_personal_access_token}&sudo=#{user.id}")

                expect(json_response['id']).to eq(user.id)
                expect(json_response).not_to have_key('note')
              end
            end

            context 'accesses the profile of another admin' do
              let(:admin_2) {create(:admin, note: '2010-10-10 | 2FA added | admin requested | www.gitlab.com')}

              it 'contains the note of the user' do
                get api("/user?private_token=#{admin_personal_access_token}&sudo=#{admin_2.id}")

                expect(json_response['id']).to eq(admin_2.id)
                expect(json_response).to have_key('note')
                expect(json_response['note']).to eq(admin_2.note)
              end
            end
          end
        end

        context 'as a regular user' do
          it 'does not contain the note of the user' do
            get api("/user", user)

            expect(json_response).not_to have_key('note')
          end
        end
      end
    end
  end
end
