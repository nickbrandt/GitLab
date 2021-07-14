# frozen_string_literal: true

module Ci
  class BuildUnscheduleService
    def initialize(build)
      @build = build
    end

    def execute
      return unprocessable_entity unless build.scheduled?

      build.unschedule!

      ServiceResponse.success(payload: build)
    end

    private

    attr_reader :build

    def unprocessable_entity
      ServiceResponse.error(message: 'Unprocessable entity', http_status: :unprocessable_entity)
    end
  end
end
