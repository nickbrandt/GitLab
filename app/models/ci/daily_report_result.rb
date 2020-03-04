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

    enum param: REPORT_PARAMS

    def self.store_coverage(pipeline)
      return unless Feature.enabled?(:ci_daily_code_coverage, default_enabled: true)

      ref_path = connection.quote(pipeline.source_ref_path)
      date = connection.quote(pipeline.created_at.to_date)
      param = params[:coverage]

      pipeline.builds.with_coverage.each do |build|
        title = connection.quote(build.group_name)

        connection.execute <<-EOF.strip_heredoc
          INSERT INTO #{table_name} (project_id, ref_path, param, title, date, last_pipeline_id, value)
          VALUES (#{build.project_id}, #{ref_path}, #{param}, #{title}, #{date}, #{pipeline.id}, #{build.coverage})
          ON CONFLICT (project_id, ref_path, param, title, date)
          DO UPDATE SET value = #{build.coverage}, last_pipeline_id = #{pipeline.id} WHERE #{table_name}.last_pipeline_id < #{pipeline.id};
        EOF
      end
    end
  end
end
