# frozen_string_literal: true

module Gitlab
  module Geo
    module Oauth
      class LogoutState
        def self.from_state(state)
          salt, encrypted, return_to = state.to_s.split(':', 3)
          self.new(salt: salt, token: encrypted, return_to: return_to)
        end

        def initialize(token:, salt: nil, return_to: nil)
          @token = token
          @salt = salt
          @return_to_location = Gitlab::ReturnToLocation.new(return_to)
        end

        def decode
          return unless salt && token

          decoded = Base64.urlsafe_decode64(token)
          decrypt = cipher(salt, :decrypt)
          decrypt.update(decoded) + decrypt.final
        rescue OpenSSL::OpenSSLError
          nil
        end

        def encode
          return unless token

          iv = salt || SecureRandom.hex(8)
          encrypt = cipher(iv, :encrypt)
          encrypted = encrypt.update(token) + encrypt.final
          encoded = Base64.urlsafe_encode64(encrypted)

          "#{iv}:#{encoded}:#{return_to}"
        rescue OpenSSL::OpenSSLError
          nil
        end

        def return_to
          return_to_location.full_path
        end

        private

        attr_reader :token, :salt, :return_to_location

        def cipher(salt, operation)
          cipher = OpenSSL::Cipher::AES.new(128, :CBC)
          cipher.__send__(operation) # rubocop:disable GitlabSecurity/PublicSend
          cipher.iv = salt
          cipher.key = Settings.attr_encrypted_db_key_base.first(16)
          cipher
        end
      end
    end
  end
end
