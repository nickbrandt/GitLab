# frozen_string_literal: true

module StatusPage
  module PublicationServiceHelpers
    include Gitlab::Utils::StrongMemoize

    def error(message, payload = {})
      ServiceResponse.error(message: message, payload: payload)
    end

    def success(payload = {})
      ServiceResponse.success(payload: payload)
    end
  end
end
