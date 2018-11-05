# frozen_string_literal: true

module Gitlab
  module Geo
    module Oauth
      class Session
        include Gitlab::Routing
        include Gitlab::Utils::StrongMemoize
        include GrapePathHelpers::NamedRouteMatcher

        def authorize_url(params = {})
          oauth_client.auth_code.authorize_url(params)
        end

        def authenticate(access_token)
          api = OAuth2::AccessToken.from_hash(oauth_client, access_token: access_token)
          api.get(api_v4_user_path).parsed
        end

        def get_token(code, params = {}, opts = {})
          oauth_client.auth_code.get_token(code, params, opts).token
        end

        private

        def oauth_application
          strong_memoize(:oauth_application) do
            Gitlab::Geo.oauth_authentication
          end
        end

        def oauth_client
          strong_memoize(:oauth_client) do
            ::OAuth2::Client.new(
              oauth_application&.uid,
              oauth_application&.secret,
              site: Gitlab::Geo.primary_node.url,
              authorize_url: oauth_authorization_path,
              token_url: oauth_token_path
            )
          end
        end
      end
    end
  end
end
