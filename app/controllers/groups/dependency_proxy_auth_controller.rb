# frozen_string_literal: true

class Groups::DependencyProxyAuthController < ApplicationController
  include DependencyProxy::Auth

  feature_category :dependency_proxy

  skip_before_action :authenticate_user!

  def pre_request
    if Feature.enabled?(:dependency_proxy_for_private_groups, default_enabled: true)
      if request.headers['HTTP_AUTHORIZATION']
        user_from_token

        render plain: '', status: :ok
      else
        respond_unauthorized!
      end
    else
      render plain: '', status: :ok
    end
  end
end
