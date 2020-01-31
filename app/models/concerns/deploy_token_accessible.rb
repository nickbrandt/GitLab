# frozen_string_literal: true

module DeployTokenAccessible
  extend ActiveSupport::Concern

  def deploy_token_create_url(opts = {})
    raise NotImplementedError
  end

  def deploy_token_revoke_url_for(token)
    raise NotImplementedError
  end
end
