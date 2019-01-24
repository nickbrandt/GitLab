# This controller's role is to mimic and rewire the GitLab OAuth
# flow routes for Jira DVCS integration.
# See https://gitlab.com/gitlab-org/gitlab-ee/issues/2381
#
class Oauth::Jira::AuthorizationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # 1. Rewire Jira OAuth initial request to our stablished OAuth authorization URL.
  def new
    session[:redirect_uri] = params['redirect_uri']

    redirect_to oauth_authorization_path(client_id: params['client_id'],
                                         response_type: 'code',
                                         redirect_uri: oauth_jira_callback_url)
  end

  # 2. Handle the callback call as we were a Github Enterprise instance client.
  def callback
    # Handling URI query params concatenation.
    redirect_uri = URI.parse(session['redirect_uri'])
    new_query = URI.decode_www_form(String(redirect_uri.query)) << ['code', params[:code]]
    redirect_uri.query = URI.encode_www_form(new_query)

    redirect_to redirect_uri.to_s
  end

  # 3. Rewire and adjust access_token request accordingly.
  def access_token
    # We have to modify request.parameters because Doorkeeper::Server reads params from there
    request.parameters[:redirect_uri] = oauth_jira_callback_url

    begin
      strategy = Doorkeeper::Server.new(self).token_request('authorization_code')
      auth_response = strategy.authorize.body
    rescue Doorkeeper::Errors::DoorkeeperError
      auth_response = {}
    end

    token_type, scope, token = auth_response['token_type'], auth_response['scope'], auth_response['access_token']

    render body: "access_token=#{token}&scope=#{scope}&token_type=#{token_type}"
  end
end
