# frozen_string_literal: true
require 'spec_helper'

describe API::ConanPackages do
  before do
    stub_licensed_features(packages: true)
  end

  describe 'GET /api/v4/packages/conan/v1/ping' do
    context 'feature flag disabled' do
      before do
        stub_feature_flags(conan_package_registry: false)
      end

      it 'responds with 404 Not Found' do
        get api('/packages/conan/v1/ping')

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'feature flag enabled' do
      it 'responds with 401 Unauthorized when no token provided' do
        get api('/packages/conan/v1/ping')

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 200 OK when valid token is provided' do
        personal_access_token = create(:personal_access_token)
        headers = { 'HTTP_AUTHORIZATION' => "Bearer #{personal_access_token.token}" }

        get api('/packages/conan/v1/ping'), headers: headers

        expect(response).to have_gitlab_http_status(200)
        expect(response.headers['X-Conan-Server-Capabilities']).to eq("")
      end

      it 'responds with 401 Unauthorized when invalid token is provided' do
        headers = { 'HTTP_AUTHORIZATION' => "Bearer wrong-token" }
        get api('/packages/conan/v1/ping'), headers: headers

        expect(response).to have_gitlab_http_status(401)
      end

      context 'packages feature disabled' do
        it 'responds with 404 Not Found' do
          stub_packages_setting(enabled: false)
          get api('/packages/conan/v1/ping')

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'GET /api/v4/packages/conan/v1/users/authenticate' do
    it 'responds with 401 Unauthorized when invalid token is provided' do
      get api("/packages/conan/v1/users/authenticate")

      expect(response).to have_gitlab_http_status(401)
    end

    it 'responds with 200 OK and the token when valid token is provided' do
      personal_access_token = create(:personal_access_token)
      headers = { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("foo", personal_access_token.token) }
      get api("/packages/conan/v1/users/authenticate"), headers: headers

      expect(response).to have_gitlab_http_status(200)
      expect(response.body).to eq(personal_access_token.token)
    end
  end
end
