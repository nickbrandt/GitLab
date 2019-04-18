# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < Groups::ApplicationController
  include SendFileUpload

  before_action :ensure_feature_enabled!
  before_action :ensure_token_granted!

  def manifest
    response = DependencyProxy::PullManifestService.new(image, tag, token).execute

    render status: response[:code], json: response[:body]
  end

  def blob
    blob = DependencyProxy::FindOrCreateBlobService
      .new(group, image, token, params[:sha]).execute

    send_upload(blob.file)
  end

  private

  def image
    params[:image]
  end

  def tag
    params[:tag]
  end

  def token
    @token
  end

  def ensure_feature_enabled!
    render_404 unless Gitlab.config.dependency_proxy.enabled &&
        group.feature_available?(:dependency_proxy) &&
        group.dependency_proxy_setting&.enabled
  end

  def ensure_token_granted!
    response = DependencyProxy::RequestTokenService.new(image).execute

    if response[:code] == 200 and response[:body].present?
      @token = response[:body]
    else
      render status: response[:code], json: response[:body]
    end
  end
end
