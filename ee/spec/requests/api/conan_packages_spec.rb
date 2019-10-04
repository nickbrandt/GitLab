# frozen_string_literal: true
require 'spec_helper'

describe API::ConanPackages do
  let(:base_secret) { SecureRandom.base64(64) }
  let(:personal_access_token) { create(:personal_access_token) }
  let(:headers) do
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('foo', personal_access_token.token) }
  end

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

  def build_auth_headers(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
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
        jwt = build_jwt(personal_access_token)
        get api('/packages/conan/v1/ping'), headers: build_auth_headers(jwt.encoded)

        expect(response).to have_gitlab_http_status(200)
        expect(response.headers['X-Conan-Server-Capabilities']).to eq("")
      end

      it 'responds with 401 Unauthorized when invalid access token ID is provided' do
        jwt = build_jwt(double(id: 12345), user_id: personal_access_token.user_id)
        get api('/packages/conan/v1/ping'), headers: build_auth_headers(jwt.encoded)

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 401 Unauthorized when invalid user is provided' do
        jwt = build_jwt(personal_access_token, user_id: 12345)
        get api('/packages/conan/v1/ping'), headers: build_auth_headers(jwt.encoded)

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 401 Unauthorized when the provided JWT is signed with different secret' do
        jwt = build_jwt(personal_access_token, secret: SecureRandom.base64(32))
        get api('/packages/conan/v1/ping'), headers: build_auth_headers(jwt.encoded)

        expect(response).to have_gitlab_http_status(401)
      end

      it 'responds with 401 Unauthorized when invalid JWT is provided' do
        get api('/packages/conan/v1/ping'), headers: build_auth_headers('invalid-jwt')

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

  describe 'GET /api/v4/packages/conan/v1/conans/search' do
    let(:project) { create(:project, :public) }
    let(:package) { create(:conan_package, project: project) }

    before do
      get api('/packages/conan/v1/conans/search'), headers: headers, params: params
    end

    subject { JSON.parse(response.body)['results'] }

    context 'returns packages with a matching name' do
      let(:params) { { q: package.name } }

      it { is_expected.to contain_exactly(package.name) }
    end

    context 'returns packages using a * wildcard' do
      let(:params) {{ q: "#{package.name[0, 3]}*" }}

      it { is_expected.to contain_exactly(package.name) }
    end

    context 'does not return non-matching packages' do
      let(:params) {{ q: "foo" }}

      it { is_expected.to be_blank }
    end
  end

  describe 'GET /api/v4/packages/conan/v1/users/authenticate' do
    it 'responds with 401 Unauthorized when invalid token is provided' do
      headers = { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('foo', 'wrong-token') }
      get api('/packages/conan/v1/users/authenticate'), headers: headers

      expect(response).to have_gitlab_http_status(401)
    end

    it 'responds with 200 OK and JWT when valid access token is provided' do
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
      get api('/packages/conan/v1/users/check_credentials'), headers: headers

      expect(response).to have_gitlab_http_status(200)
    end

    it 'responds with a 401 Unauthorized when an invalid token is used' do
      get api('/packages/conan/v1/users/check_credentials'), headers: build_auth_headers('invalid-token')

      expect(response).to have_gitlab_http_status(401)
    end
  end

  shared_examples 'rejected invalid recipe' do
    context 'with invalid recipe url' do
      let(:recipe) { '../../foo++../..' }
      it 'returns 400' do
        subject

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  context 'recipe endpoints' do
    let(:jwt) { build_jwt(personal_access_token) }
    let(:headers) { build_auth_headers(jwt.encoded) }
    let(:recipe) { 'my-package-name/1.0/username/channel' }

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe' do
      subject { get api("/packages/conan/v1/conans/#{recipe}"), headers: headers }

      it_behaves_like 'rejected invalid recipe'

      it 'responds with an empty response' do
        subject

        expect(response.body).to be {}
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/digest' do
      subject { get api("/packages/conan/v1/conans/#{recipe}/digest"), headers: headers }

      it_behaves_like 'rejected invalid recipe'

      it 'responds with a 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/upload_urls' do
      let(:params) do
        { "conanfile.py": 24,
          "conanmanifext.txt": 123 }
      end
      subject { post api("/packages/conan/v1/conans/#{recipe}/upload_urls"), params: params, headers: headers }

      it_behaves_like 'rejected invalid recipe'

      it 'returns a set of upload urls for the files requested' do
        subject

        expected_response = {
          'conanfile.py':      "#{Settings.gitlab.base_url}/api/v4/packages/conan/v1/files/#{recipe}/-/0/export/conanfile.py",
          'conanmanifest.txt': "#{Settings.gitlab.base_url}/api/v4/packages/conan/v1/files/#{recipe}/-/0/export/conanmanifest.txt"
        }

        expect(response.body).to eq expected_response.to_json
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/packages/:package_id' do
      subject { get api("/packages/conan/v1/conans/#{recipe}/packages/123456789"), headers: headers }

      it_behaves_like 'rejected invalid recipe'

      it 'responds with an empty response' do
        subject

        expect(response.body).to be {}
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/packages/:package_id/digest' do
      subject { get api("/packages/conan/v1/conans/#{recipe}/packages/123456789/digest"), headers: headers }

      it_behaves_like 'rejected invalid recipe'

      it 'responds with a 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET /api/v4/packages/conan/v1/conans/*recipe/packages/:package_id/upload_urls' do
      let(:params) do
        { "conaninfo.txt": 24,
          "conanmanifext.txt": 123,
          "conan_package.tgz": 523 }
      end

      context 'valid recipe' do
        subject { post api("/packages/conan/v1/conans/#{recipe}/packages/123456789/upload_urls"), params: params, headers: headers }

        it_behaves_like 'rejected invalid recipe'

        it 'returns a set of upload urls for the files requested' do
          expected_response = {
            'conaninfo.txt':     "#{Settings.gitlab.base_url}/api/v4/packages/conan/v1/files/#{recipe}/-/0/package/123456789/0/conaninfo.txt",
            'conanmanifest.txt': "#{Settings.gitlab.base_url}/api/v4/packages/conan/v1/files/#{recipe}/-/0/package/123456789/0/conanmanifest.txt",
            'conan_package.tgz': "#{Settings.gitlab.base_url}/api/v4/packages/conan/v1/files/#{recipe}/-/0/package/123456789/0/conan_package.tgz"
          }
          subject

          expect(response.body).to eq expected_response.to_json
        end
      end
    end
  end
end
