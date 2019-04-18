# frozen_string_literal: true

module DependencyProxy
  class PullManifestService < DependencyProxy::BaseService
    def initialize(image, tag, token)
      @image = image
      @tag = tag
      @token = token
    end

    def execute
      response = Gitlab::HTTP.get(manifest_url, headers: auth_headers)

      to_response(response.code, response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout => exception
      to_response(599, exception.message)
    end

    private

    def manifest_url
      registry.manifest_url(@image, @tag)
    end
  end
end
