# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < Groups::ApplicationController
  include SendFileUpload

  before_action :ensure_feature_enabled!

  def manifest
    output = DependencyProxy::PullManifestService.new(image, tag, token).execute

    render json: output
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
    @token ||= request_token
  end

  def request_token
    DependencyProxy::RequestTokenService.new(image).execute
  end

  def ensure_feature_enabled!
    render_404 unless Gitlab.config.dependency_proxy.enabled &&
        group.feature_available?(:dependency_proxy) &&
        group.dependency_proxy_setting&.enabled
  end
end
