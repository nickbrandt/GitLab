# frozen_string_literal: true
module API
  class ConanPackages < Grape::API
    before do
      not_found! unless Feature.enabled?(:conan_package_registry)
      require_packages_enabled!
    end

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def jwt_secret
        ::Settings.attr_encrypted_db_key_base_32
      end
    end

    namespace 'packages/conan/v1/users/' do
      format :txt

      desc 'Authenticate user' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'authenticate' do
        encoded_credentials = headers['Authorization'].to_s.split('Basic ', 2).second
        token = Base64.decode64(encoded_credentials || '').split(':', 2).second
        request.env['HTTP_PRIVATE_TOKEN'] = token

        authenticate!

        jwt = JSONWebToken::HMACToken.new(jwt_secret)
        jwt['pat'] = access_token.id
        jwt.expire_time = jwt.issued_at + 1.hour
        jwt.encoded
      end
    end

    namespace 'packages/conan/v1/' do
      before do
        require_conan_authentication!
      end

      helpers do
        def require_conan_authentication!
          jwt = headers['Authorization'].to_s.split('Bearer ', 2).second
          payload = JSONWebToken::HMACToken.decode(jwt, jwt_secret).first
          @access_token = PersonalAccessToken.find_by_id(payload['pat'])

          authenticate!
        rescue JWT::DecodeError
          unauthorized!
        end
      end

      desc 'Ping the Conan API' do
        detail 'This feature was introduced in GitLab 12.2'
      end
      get 'ping' do
        header 'X-Conan-Server-Capabilities', [].join(',')
      end
    end
  end
end
