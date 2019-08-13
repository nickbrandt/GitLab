# frozen_string_literal: true

module Gitlab
  class ConanToken
    HMAC_KEY = 'gitlab-conan-packages'.freeze

    attr_reader :personal_access_token_id, :user_id

    class << self
      def from_personal_access_token(personal_access_token)
        new(personal_access_token_id: personal_access_token.id, user_id: personal_access_token.user_id)
      end

      def decode(jwt)
        payload = JSONWebToken::HMACToken.decode(jwt, secret).first

        new(personal_access_token_id: payload['pat'], user_id: payload['u'])
      end

      def secret
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::SHA256.new,
          ::Settings.attr_encrypted_db_key_base,
          HMAC_KEY
        )
      end
    end

    def initialize(personal_access_token_id:, user_id:)
      @personal_access_token_id = personal_access_token_id
      @user_id = user_id
    end

    def to_jwt
      hmac_token.encoded
    end

    private

    def hmac_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['pat'] = personal_access_token_id
        token['u'] = user_id
        token.expire_time = token.issued_at + 1.hour
      end
    end
  end
end
