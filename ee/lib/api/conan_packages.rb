# frozen_string_literal: true
module API
  class ConanPackages < Grape::API
    HMAC_KEY = 'gitlab-conan-packages'.freeze

    helpers ::API::Helpers::PackagesHelpers

    before do
      not_found! unless Feature.enabled?(:conan_package_registry)
      require_packages_enabled!

      # Personal access token will be extracted from Bearer or Basic authorization
      # in the overriden find_personal_access_token helper
      authenticate!
    end

    namespace 'packages/conan/v1/users/' do
      format :txt

      desc 'Authenticate user' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'authenticate' do
        jwt = JSONWebToken::HMACToken.new(jwt_secret)
        jwt['pat'] = access_token.id
        jwt['u'] = access_token.user_id
        jwt.expire_time = jwt.issued_at + 1.hour

        jwt.encoded
      end
    end

    namespace 'packages/conan/v1/' do
      desc 'Ping the Conan API' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'ping' do
        header 'X-Conan-Server-Capabilities', [].join(',')
      end
    end

    helpers do
      def find_personal_access_token
        personal_access_token = find_personal_access_token_from_conan_jwt ||
          find_personal_access_token_from_conan_http_basic_auth

        personal_access_token || unauthorized!
      end

      # We need to override this one because it
      # looks into Bearer authorization header
      def find_oauth_access_token
      end

      def find_personal_access_token_from_conan_jwt
        jwt = Doorkeeper::OAuth::Token.from_bearer_authorization(current_request)
        return unless jwt

        payload = JSONWebToken::HMACToken.decode(jwt, jwt_secret).first

        PersonalAccessToken.find_by_id_and_user_id(payload['pat'], payload['u'])
      rescue JWT::DecodeError
        unauthorized!
      end

      def find_personal_access_token_from_conan_http_basic_auth
        encoded_credentials = headers['Authorization'].to_s.split('Basic ', 2).second
        token = Base64.decode64(encoded_credentials || '').split(':', 2).second
        return unless token

        PersonalAccessToken.find_by_token(token)
      end

      def jwt_secret
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::SHA256.new,
          ::Settings.attr_encrypted_db_key_base,
          HMAC_KEY
        )
      end
    end
  end
end
