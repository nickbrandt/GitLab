# frozen_string_literal: true

module Ci
  class DailyCodeCoverageService
    def execute(pipeline)
      return unless Feature.enabled?(:ci_daily_code_coverage, default_enabled: true)

      pipeline.builds.with_coverage.each do |build|
        DailyCodeCoverage.create_or_update_for_build(build)
      end
    end
  end
end
