# frozen_string_literal: true

module Ci
  class DailyReportResult < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :last_pipeline, class_name: 'Ci::Pipeline', foreign_key: :last_pipeline_id
    belongs_to :project

    # TODO: Refactor this out when BuildReportResult is implemented.
    # They both need to share the same enum values for param.
    REPORT_PARAMS = {
      coverage: 12
    }.freeze

    enum param_type: REPORT_PARAMS

    def self.store_coverage(pipeline)
      return unless Feature.enabled?(:ci_daily_code_coverage, default_enabled: true)

      base_attrs = {
        project_id: pipeline.project_id,
        ref_path: pipeline.source_ref_path,
        param_type: param_types[:coverage],
        date: pipeline.created_at.to_date,
        last_pipeline_id: pipeline.id
      }

      data = pipeline.builds.with_coverage.map do |build|
        base_attrs.merge(
          title: build.group_name,
          value: build.coverage
        )
      end

      upsert_all(data, unique_by: :index_daily_report_results_unique_columns) if data.any?
    end
  end
end
