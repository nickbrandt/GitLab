# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependencyProxyAuthController do
  include DependencyProxyHelpers

  describe 'GET #pre_request' do
    subject { get :pre_request }

    context 'feature flag disabled' do
      before do
        stub_feature_flags(dependency_proxy_for_private_groups: false)
      end

      it 'returns successfully', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'without JWT' do
      it 'returns unauthorized with oauth realm', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to eq DependencyProxy::Registry.authenticate_header
      end
    end

    context 'with valid JWT' do
      let_it_be(:user) { create(:user) }
      let(:jwt) { build_jwt(user) }
      let(:token_header) { "Bearer #{jwt.encoded}" }

      before do
        request.headers['HTTP_AUTHORIZATION'] = token_header
      end

      it { is_expected.to have_gitlab_http_status(:success) }
    end

    context 'with invalid JWT' do
      let(:jwt) { build_jwt(double('bad_user', id: 999)) }
      let(:token_header) { "Bearer #{jwt.encoded}" }

      before do
        request.headers['HTTP_AUTHORIZATION'] = token_header
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
