# frozen_string_literal: true

module Gitlab
  module Geo
    module Oauth
      class LoginState
        attr_reader :return_to

        def self.from_state(state)
          salt, hmac, return_to = state.to_s.split(':', 3)
          self.new(salt: salt, hmac: hmac, return_to: return_to)
        end

        def initialize(return_to:, salt: nil, hmac: nil)
          @return_to = return_to
          @salt = salt
          @hmac = hmac
        end

        def valid?
          return false unless salt.present? && hmac.present?

          hmac == generate_hmac
        end

        def encode
          "#{salt}:#{generate_hmac}:#{return_to}"
        end

        private

        attr_reader :hmac

        def generate_hmac
          digest = OpenSSL::Digest::SHA256.new
          key = Gitlab::Application.secrets.secret_key_base + salt

          OpenSSL::HMAC.hexdigest(digest, key, return_to.to_s)
        end

        def salt
          @salt ||= SecureRandom.hex(8)
        end
      end
    end
  end
end
