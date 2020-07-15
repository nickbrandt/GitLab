# frozen_string_literal: true

module Gitlab
  module Geo
    module Oauth
      class LoginState
        attr_reader :return_to

        def self.from_state(state)
          salt, token, return_to = state.to_s.split(':', 3)
          self.new(salt: salt, token: token, return_to: return_to)
        end

        def initialize(return_to:, salt: nil, token: nil)
          @return_to = Gitlab::ReturnToLocation.new(return_to).full_path
          @salt = salt
          @token = token
        end

        def encode
          "#{salt}:#{hmac_token}:#{return_to}"
        end

        def valid?
          return false unless salt.present? && token.present?

          decoded_token = JSONWebToken::HMACToken.decode(token, key).first
          secure_compare(decoded_token.dig('data', 'return_to'))
        rescue JWT::DecodeError
          false
        end

        private

        attr_reader :token

        def expiration_time
          1.minute
        end

        def hmac_token
          hmac_token = JSONWebToken::HMACToken.new(key)
          hmac_token.expire_time = Time.current + expiration_time
          hmac_token[:data] = { return_to: return_to.to_s }
          hmac_token.encoded
        end

        def key
          ActiveSupport::KeyGenerator
            .new(Gitlab::Application.secrets.secret_key_base)
            .generate_key(salt)
        end

        def salt
          @salt ||= SecureRandom.hex(8)
        end

        def secure_compare(value)
          ActiveSupport::SecurityUtils.secure_compare(return_to.to_s, value)
        end
      end
    end
  end
end
