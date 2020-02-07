# frozen_string_literal: true

module Ci
  class DailyCodeCoverageService
    def execute(pipeline)
      pipeline.builds.with_coverage.each do |build|
        daily_coverage = daily_coverage_for(pipeline, build)
        daily_coverage.with_lock do
          daily_coverage.coverage = build.coverage
          daily_coverage.last_pipeline_id = pipeline.id
          daily_coverage.save
        end
      end
    end

    private

    def daily_coverage_for(pipeline, build)
      # rubocop: disable CodeReuse/ActiveRecord
      DailyCodeCoverage.find_or_initialize_by(
        project_id: pipeline.project_id,
        ref: pipeline.ref,
        name: build.name,
        date: pipeline.created_at.to_date
      )
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
