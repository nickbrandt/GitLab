# frozen_string_literal: true

module DependencyProxy
  class RequestTokenService < DependencyProxy::BaseService
    def initialize(image)
      @image = image
    end

    def execute
      response = Gitlab::HTTP.get(auth_url)

      if response.code == 200
        to_response(200, JSON.parse(response.body)['token'])
      else
        to_response(response.code, 'Expected 200 response code for an access token')
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => exception
      to_response(599, exception.message)
    rescue JSON::ParserError
      to_response(500, 'Failed to parse a response body for an access token')
    end

    private

    def auth_url
      registry.auth_url(@image)
    end
  end
end
