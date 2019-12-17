# frozen_string_literal: true

require 'spec_helper'

describe Admin::CredentialsController do
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

          expect(response).to have_gitlab_http_status(200)
        end

        describe 'filtering by type of credential' do
          let_it_be(:personal_access_tokens) { create_list(:personal_access_token, 2) }

          shared_examples_for 'filtering by `personal_access_tokens`' do
            it do
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

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'non-admin user' do
      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        get :index

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
