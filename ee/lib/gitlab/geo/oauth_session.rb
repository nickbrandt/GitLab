module Gitlab
  module Geo
    class OauthSession
      include ActiveModel::Model

      attr_accessor :access_token
      attr_accessor :state
      attr_accessor :return_to

      def oauth_state_valid?
        salt, hmac, return_to = state.to_s.split(':', 3)
        LoginState.new(salt, return_to).valid?(hmac)
      end

      def generate_oauth_state
        self.state = LoginState.new(oauth_salt, return_to).encode
      end

      def generate_logout_state
        self.state = LogoutState.new(oauth_salt, access_token, return_to).encode
      end

      def extract_logout_token
        salt, encrypted, return_to = state.to_s.split(':', 3)
        LogoutState.new(salt, encrypted, return_to).decode
      end

      def get_oauth_state_return_to
        state.split(':', 3)[2] if state
      end

      def get_oauth_state_return_to_full_path
        ReturnToLocation.new(get_oauth_state_return_to).full_path
      end

      def authorize_url(params = {})
        oauth_client.auth_code.authorize_url(params)
      end

      def get_token(code, params = {}, opts = {})
        oauth_client.auth_code.get_token(code, params, opts).token
      end

      def authenticate_with_gitlab(access_token)
        return false unless access_token

        api = OAuth2::AccessToken.from_hash(oauth_client, access_token: access_token)
        api.get('/api/v4/user').parsed
      end

      private

      class LoginState
        def initialize(salt, return_to)
          @salt      = salt
          @return_to = return_to
        end

        def valid?(hmac)
          return false unless salt && return_to

          hmac == generate_hmac
        end

        def encode
          return unless salt && return_to

          "#{salt}:#{generate_hmac}:#{return_to}"
        end

        private

        attr_reader :salt, :return_to

        def generate_hmac
          digest = OpenSSL::Digest.new('sha256')
          key    = Gitlab::Application.secrets.secret_key_base + salt

          OpenSSL::HMAC.hexdigest(digest, key, return_to)
        end
      end

      class LogoutState
        def initialize(salt, token, return_to)
          @salt      = salt
          @token     = token
          @return_to = return_to
        end

        def decode
          return unless salt && token

          decrypt = cipher(salt, :decrypt)
          decrypt.update(Base64.urlsafe_decode64(token)) + decrypt.final
        rescue OpenSSL::OpenSSLError
          nil
        end

        def encode
          return unless token

          encrypt   = cipher(salt, :encrypt)
          encrypted = encrypt.update(token) + encrypt.final
          encoded   = Base64.urlsafe_encode64(encrypted)

          "#{salt}:#{encoded}:#{full_path}"
        rescue OpenSSL::OpenSSLError
          nil
        end

        private

        attr_reader :salt, :token, :return_to

        def cipher(salt, operation)
          cipher = OpenSSL::Cipher::AES.new(128, :CBC)
          cipher.__send__(operation) # rubocop:disable GitlabSecurity/PublicSend
          cipher.iv = salt
          cipher.key = Settings.attr_encrypted_db_key_base[0..15]
          cipher
        end

        def full_path
          ReturnToLocation.new(return_to).full_path
        end
      end

      class ReturnToLocation
        def initialize(location)
          @location = location
        end

        def full_path
          uri = parse_uri(location)

          if uri
            path = remove_domain_from_uri(uri)
            path = add_fragment_back_to_path(uri, path)

            path
          end
        end

        private

        attr_reader :location

        def parse_uri(location)
          location && URI.parse(location.sub(%r{\A\/\/+}, '/'))
        rescue URI::InvalidURIError
          nil
        end

        def remove_domain_from_uri(uri)
          [uri.path.sub(%r{\A\/+}, '/'), uri.query].compact.join('?')
        end

        def add_fragment_back_to_path(uri, path)
          [path, uri.fragment].compact.join('#')
        end
      end

      def oauth_salt
        @oauth_salt ||= SecureRandom.hex(8)
      end

      def oauth_client
        @oauth_client ||= begin
          ::OAuth2::Client.new(
            oauth_app.uid,
            oauth_app.secret,
            {
              site: primary_node_url,
              authorize_url: 'oauth/authorize',
              token_url: 'oauth/token'
            }
          )
        end
      end

      def oauth_app
        Gitlab::Geo.oauth_authentication
      end

      def primary_node_url
        Gitlab::Geo.primary_node.url
      end
    end
  end
end
