# frozen_string_literal: true

module DependencyProxy
  class BaseService
    private

    def registry
      DependencyProxy::Registry.new
    end

    def auth_headers
      {
        Authorization: "Bearer #{@token}"
      }
    end
  end
end
