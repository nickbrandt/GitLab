# frozen_string_literal: true

class ScimOauthAccessTokenEntity < Grape::Entity
  expose :scim_api_url do |scim|
    Gitlab::Routing.url_helpers.group_scim_oauth_url(scim.group)
  end

  expose :token, as: :scim_token
end
