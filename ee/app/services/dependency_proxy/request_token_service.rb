# frozen_string_literal: true

module DependencyProxy
  class RequestTokenService < DependencyProxy::BaseService
    def initialize(image)
      @image = image
    end

    def execute
      response = Gitlab::HTTP.get(auth_url)

      JSON.parse(response.body)['token']
    end

    private

    def auth_url
      registry.auth_url(@image)
    end
  end
end
