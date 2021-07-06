# frozen_string_literal: true

module Auth
  class DependencyProxyAuthenticationService < BaseService
    AUDIENCE = 'dependency_proxy'
    HMAC_KEY = 'gitlab-dependency-proxy'
    DEFAULT_EXPIRE_TIME = 1.minute

    def execute(authentication_abilities:)
      return error('dependency proxy not enabled', 404) unless ::Gitlab.config.dependency_proxy.enabled
      return error('access forbidden', 403) unless current_user.is_a?(User) || current_user.is_a?(DeployToken)

      { token: authorized_token.encoded }
    end

    class << self
      include ::Gitlab::Utils::StrongMemoize

      def secret
        strong_memoize(:secret) do
          OpenSSL::HMAC.hexdigest(
            'sha256',
            ::Settings.attr_encrypted_db_key_base,
            HMAC_KEY
          )
        end
      end

      def token_expire_at
        Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes
      end
    end

    private

    def authorized_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['user_id'] = current_user.id if current_user.is_a?(User)
        token['deploy_token'] = current_user.token if current_user.is_a?(DeployToken)
        token.expire_time = self.class.token_expire_at
      end
    end
  end
end
