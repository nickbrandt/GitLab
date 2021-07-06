# frozen_string_literal: true

module DependencyProxy
  module Auth
    extend ActiveSupport::Concern

    included do
      attr_reader :authentication_result

      delegate :actor, to: :authentication_result, allow_nil: true
      delegate :type, to: :authentication_result, allow_nil: true, prefix: :auth_result

      alias_method :user, :actor
      alias_method :authenticated_user, :actor

      # We disable `authenticate_user!` since the `DependencyProxy::Auth` performs auth using JWT token
      skip_before_action :authenticate_user!, raise: false

      prepend_before_action :authenticate_user_from_jwt_token!
    end

    def authenticate_user_from_jwt_token!
      return unless dependency_proxy_for_private_groups?

      if Feature.enabled?(:dependency_proxy_deploy_tokens)
        authenticate_with_http_token do |token, _|
          @authentication_result = Gitlab::Auth::Result.new(nil, nil, nil, nil) # rubocop:disable Gitlab/ModuleWithInstanceVariables

          found_user = user_from_token(token)
          sign_in(found_user) if found_user.is_a?(User)
        end

        request_bearer_token! unless authenticated_user
      else
        authenticate_with_http_token do |token, _|
          user = user_from_token(token)
          sign_in(user) if user
        end

        request_bearer_token! unless current_user
      end
    end

    private

    def dependency_proxy_for_private_groups?
      Feature.enabled?(:dependency_proxy_for_private_groups, default_enabled: true)
    end

    def request_bearer_token!
      # unfortunately, we cannot use https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html#method-i-authentication_request
      response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
      render plain: '', status: :unauthorized
    end

    def user_from_token(token)
      token_payload = DependencyProxy::AuthTokenService.decoded_token_payload(token)
      return User.find(token_payload['user_id']) unless Feature.enabled?(:dependency_proxy_deploy_tokens)

      if token_payload['user_id']
        token_user = User.find(token_payload['user_id'])
        @authentication_result = Gitlab::Auth::Result.new(token_user, nil, :user, []) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        return token_user
      elsif token_payload['deploy_token']
        deploy_token = DeployToken.active.find_by_token(token_payload['deploy_token'])
        @authentication_result = Gitlab::Auth::Result.new(deploy_token, nil, :deploy_token, []) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        return deploy_token
      end

      nil
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature
      nil
    end
  end
end
