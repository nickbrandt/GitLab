# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < Groups::ApplicationController
  include SendFileUpload

  before_action :ensure_feature_enabled!
  before_action :ensure_token_granted!

  attr_reader :token

  def manifest
    result = DependencyProxy::PullManifestService.new(image, tag, token).execute

    if result[:status] == :success
      render json: result[:manifest]
    else
      render status: result[:http_status], json: result[:message]
    end
  end

  def blob
    result = DependencyProxy::FindOrCreateBlobService
      .new(group, image, token, params[:sha]).execute

    if result[:status] == :success
      send_upload(result[:blob].file)
    else
      head result[:http_status]
    end
  end

  private

  def image
    params[:image]
  end

  def tag
    params[:tag]
  end

  def ensure_feature_enabled!
    render_404 unless Gitlab.config.dependency_proxy.enabled &&
        group.feature_available?(:dependency_proxy) &&
        group.dependency_proxy_setting&.enabled
  end

  def ensure_token_granted!
    result = DependencyProxy::RequestTokenService.new(image).execute

    if result[:status] == :success
      @token = result[:token]
    else
      render status: result[:http_status], json: result[:message]
    end
  end
end
