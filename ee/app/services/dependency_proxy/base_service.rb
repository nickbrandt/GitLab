# frozen_string_literal: true

module DependencyProxy
  class BaseService
    private

    def registry
      DependencyProxy::Registry
    end

    def auth_headers
      {
        Authorization: "Bearer #{@token}"
      }
    end

    def to_response(code, body)
      {
        code: code,
        body: body
      }
    end
  end
end
