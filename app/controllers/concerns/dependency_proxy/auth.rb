# frozen_string_literal: true

module DependencyProxy::Auth
  extend ActiveSupport::Concern

  def respond_unauthorized!
    response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
    render plain: '', status: :unauthorized
  end

  def user_from_token
    token = Doorkeeper::OAuth::Token.from_bearer_authorization(request)
    token_payload = JSONWebToken::HMACToken.decode(token, ::Auth::DependencyProxyAuthenticationService.secret).first
    User.find(token_payload['user_id'])
  end
end
