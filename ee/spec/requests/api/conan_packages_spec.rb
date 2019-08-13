# frozen_string_literal: true
require 'spec_helper'

describe API::ConanPackages do
  let(:base_secret) { SecureRandom.base64(64) }

  let(:jwt_secret) do
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest::SHA256.new,
      base_secret,
      Gitlab::ConanToken::HMAC_KEY
    )
  end

  before do
    stub_licensed_features(packages: true)
    allow(Settings).to receive(:attr_encrypted_db_key_base).and_return(base_secret)
  end

  def build_jwt(personal_access_token, secret: jwt_secret, user_id: nil)
    JSONWebToken::HMACToken.new(secret).tap do |jwt|
      jwt['pat'] = personal_access_token.id
      jwt['u'] = user_id || personal_access_token.user_id
    end
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
        jwt = build_jwt(personal_access_token)
        headers = { 'HTTP_AUTHORIZATION' => "Bearer #{jwt.encoded}" }

        get api('/packages/conan/v1/ping'), headers: headers

        expect(response).to have_gitlab_http_status(200)
        expect(response.headers['X-Conan-Server-Capabilities']).to eq("")
      end

      it 'responds with 401 Unauthorized when invalid access token ID is provided' do
        personal_access_token = create(:personal_access_token)
        jwt = build_jwt(double(id: 12345), user_id: personal_access_token.user_id)
        headers = { 'HTTP_AUTHORIZATION' => "Bearer #{jwt.encoded}" }
        get api('/packages/conan/v1/ping'), headers: headers

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 401 Unauthorized when invalid user is provided' do
        personal_access_token = create(:personal_access_token)
        jwt = build_jwt(personal_access_token, user_id: 12345)
        headers = { 'HTTP_AUTHORIZATION' => "Bearer #{jwt.encoded}" }
        get api('/packages/conan/v1/ping'), headers: headers

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 401 Unauthorized when the provided JWT is signed with different secret' do
        personal_access_token = create(:personal_access_token)
        jwt = build_jwt(personal_access_token, secret: SecureRandom.base64(32))
        headers = { 'HTTP_AUTHORIZATION' => "Bearer #{jwt.encoded}" }
        get api('/packages/conan/v1/ping'), headers: headers

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 401 Unauthorized when invalid JWT is provided' do
        headers = { 'HTTP_AUTHORIZATION' => "Bearer invalid-jwt" }
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
      headers = { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('foo', 'wrong-token') }
      get api('/packages/conan/v1/users/authenticate'), headers: headers

      expect(response).to have_gitlab_http_status(401)
    end

    it 'responds with 200 OK and JWT when valid access token is provided' do
      personal_access_token = create(:personal_access_token)
      headers = { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('foo', personal_access_token.token) }
      get api('/packages/conan/v1/users/authenticate'), headers: headers

      expect(response).to have_gitlab_http_status(200)

      payload = JSONWebToken::HMACToken.decode(response.body, jwt_secret).first
      expect(payload['pat']).to eq(personal_access_token.id)
      expect(payload['u']).to eq(personal_access_token.user_id)

      duration = payload['exp'] - payload['iat']
      expect(duration).to eq(1.hour)
    end
  end

  describe 'GET /api/v4/packages/conan/v1/users/check_credentials' do
    it 'responds with a 200 OK' do
      get api('/packages/conan/v1/users/check_credentials')

      expect(response).to have_gitlab_http_status(200)
    end
  end

  context 'recipe endpoints' do
    let(:recipe) { 'my-package-name/1.0/username/channel' }

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe' do
      it 'responds with an empty response' do
        get api("/packages/conan/v1/conans/#{recipe}")

        expect(response.body).to be {}
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/digest' do
      it 'responds with a 404' do
        get api("/packages/conan/v1/conans/#{recipe}/digest")

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/upload_urls' do
      let(:params) do
        { "conanfile.py": 24,
          "conanmanifext.txt": 123 }
      end
      it 'returns a set of upload urls for the files requested' do
        post api("/packages/conan/v1/conans/#{recipe}/upload_urls"), params: params

        expected_response = {
          'conanfile.py':      "http://localhost:3001/api/v4/packages/conan/v1/files/#{recipe}/0/export/conanfile.py",
          'conanmanifest.txt': "http://localhost:3001/api/v4/packages/conan/v1/files/#{recipe}/0/export/conanmanifest.txt"
        }

        expect(response.body).to eq expected_response.to_json
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/packages/:package_id' do
      it 'responds with an empty response' do
        get api("/packages/conan/v1/conans/#{recipe}/packages/123456789")

        expect(response.body).to be {}
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/packages/:package_id/digest' do
      it 'responds with a 404' do
        get api("/packages/conan/v1/conans/#{recipe}/packages/123456789/digest")

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/packages/:package_id/upload_urls' do
      let(:params) do
        { "conaninfo.txt": 24,
          "conanmanifext.txt": 123,
          "conan_package.tgz": 523 }
      end

      it 'returns a set of upload urls for the files requested' do
        post api("/packages/conan/v1/conans/#{recipe}/packages/123456789/upload_urls"), params: params

        expected_response = {
          'conaninfo.txt':     "http://localhost:3001/api/v4/packages/conan/v1/files/#{recipe}/0/package/12345/0/conaninfo.py",
          'conanmanifest.txt': "http://localhost:3001/api/v4/packages/conan/v1/files/#{recipe}/0/package/12345/0/conanmanifest.txt",
          'conanmanifest.tgz': "http://localhost:3001/api/v4/packages/conan/v1/files/#{recipe}/0/package/12345/0/conan_package.txt"
        }

        expect(response.body).to eq expected_response.to_json
      end
    end
  end
end
