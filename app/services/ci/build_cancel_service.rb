# frozen_string_literal: true

module Ci
  class BuildCancelService
    def initialize(build)
      @build = build
    end

    def execute
      return unprocessable_entity unless build.cancelable?

      build.cancel

      ServiceResponse.success(payload: build)
    end

    private

    attr_reader :build

    def unprocessable_entity
      ServiceResponse.error(message: 'Unprocessable entity', http_status: :unprocessable_entity)
    end
  end
end
