# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CredentialsController do
  describe 'GET #index' do
    context 'admin user' do
      before do
        sign_in(create(:admin))
      end

      context 'when `credentials_inventory` feature is enabled' do
        before do
          stub_licensed_features(credentials_inventory: true)
        end

        it 'responds with 200' do
          get :index

          expect(response).to have_gitlab_http_status(:ok)
        end

        it_behaves_like 'tracking unique visits', :index do
          let(:target_id) { 'i_compliance_credential_inventory' }
        end

        describe 'filtering by type of credential' do
          let_it_be(:personal_access_tokens) { create_list(:personal_access_token, 2) }

          shared_examples_for 'filtering by `personal_access_tokens`' do
            specify do
              get :index, params: params

              expect(assigns(:credentials)).to match_array(personal_access_tokens)
            end
          end

          context 'no credential type specified' do
            let(:params) { {} }

            it_behaves_like 'filtering by `personal_access_tokens`'
          end

          context 'non-existent credential type specified' do
            let(:params) { { filter: 'non_existent_credential_type' } }

            it_behaves_like 'filtering by `personal_access_tokens`'
          end

          context 'credential type specified as `personal_access_tokens`' do
            let(:params) { { filter: 'personal_access_tokens' } }

            it_behaves_like 'filtering by `personal_access_tokens`'
          end

          context 'credential type specified as `ssh_keys`' do
            it 'filters by ssh keys' do
              ssh_keys =  create_list(:personal_key, 2)

              get :index, params: { filter: 'ssh_keys' }

              expect(assigns(:credentials)).to match_array(ssh_keys)
            end
          end
        end
      end

      context 'when `credentials_inventory` feature is disabled' do
        before do
          stub_licensed_features(credentials_inventory: false)
        end

        it 'returns 404' do
          get :index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT #revoke' do
    context 'admin user' do
      let_it_be(:current_user) { create(:admin) }

      before do
        sign_in(current_user)
      end

      context 'when `credentials_inventory` feature is enabled' do
        before do
          stub_licensed_features(credentials_inventory: true)
        end

        context 'non-existent personal access token specified' do
          it 'returns 404' do
            put :revoke, params: { id: 999999999999999999999999999999999 }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        describe 'with an existing personal access token' do
          context 'does not have permissions to revoke the credential' do
            let_it_be(:personal_access_token) { create(:personal_access_token) }

            before do
              expect(Ability).to receive(:allowed?).with(current_user, :log_in, :global) { true }
              expect(Ability).to receive(:allowed?).with(current_user, :revoke_token, personal_access_token) { false }
            end

            it 'returns the flash error message' do
              put :revoke, params: { id: personal_access_token.id }

              expect(response).to redirect_to(admin_credentials_path)
              expect(flash[:alert]).to eql 'Not permitted to revoke'
            end
          end

          context 'personal access token is already revoked' do
            let_it_be(:personal_access_token) { create(:personal_access_token, revoked: true) }

            it 'returns the flash success message' do
              put :revoke, params: { id: personal_access_token.id }

              expect(response).to redirect_to(admin_credentials_path)
              expect(flash[:notice]).to eql 'Revoked personal access token %{personal_access_token_name}!' % { personal_access_token_name: personal_access_token.name }
            end
          end

          context 'personal access token is already expired' do
            let_it_be(:personal_access_token) { create(:personal_access_token, expires_at: 5.days.ago) }

            it 'returns the flash success message' do
              put :revoke, params: { id: personal_access_token.id }

              expect(response).to redirect_to(admin_credentials_path)
              expect(flash[:notice]).to eql 'Revoked personal access token %{personal_access_token_name}!' % { personal_access_token_name: personal_access_token.name }
            end
          end

          context 'personal access token is not revoked or expired' do
            let_it_be(:personal_access_token) { create(:personal_access_token) }

            it 'returns the flash success message' do
              put :revoke, params: { id: personal_access_token.id }

              expect(response).to redirect_to(admin_credentials_path)
              expect(flash[:notice]).to eql 'Revoked personal access token %{personal_access_token_name}!' % { personal_access_token_name: personal_access_token.name }
            end
          end
        end
      end

      context 'when `credentials_inventory` feature is disabled' do
        let_it_be(:personal_access_token) { create(:personal_access_token) }

        before do
          stub_licensed_features(credentials_inventory: false)
        end

        it 'returns 404' do
          put :revoke, params: { id: personal_access_token.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      let_it_be(:personal_access_token) { create(:personal_access_token) }

      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        put :revoke, params: { id: personal_access_token.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
