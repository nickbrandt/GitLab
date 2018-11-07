module Oauth2
  class LogoutTokenValidationService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :state

    def initialize(user, params = {})
      @current_user = user
      @state = params[:state]
    end

    def execute
      return error('Access token could not be found') unless access_token.present?

      status = AccessTokenValidationService.new(access_token).validate
      return error(status) unless status == AccessTokenValidationService::VALID

      user = User.find(access_token.resource_owner_id)

      if user && user == current_user
        success(return_to: user_return_to)
      else
        error('User could not be found')
      end
    end

    private

    def access_token
      strong_memoize(:access_token) do
        logout_token = oauth_session.extract_logout_token

        if logout_token&.is_utf8?
          Doorkeeper::AccessToken.by_token(logout_token)
        else
          nil
        end
      end
    end

    def oauth_session
      @oauth_session ||= Gitlab::Geo::OauthSession.new(state: state)
    end

    def user_return_to
      full_path = oauth_session.get_oauth_state_return_to_full_path
      Gitlab::Utils.append_path(geo_node_url, full_path)
    end

    def geo_node_url
      GeoNode.find_by_oauth_application_id(access_token.application_id)&.url
    end
  end
end
