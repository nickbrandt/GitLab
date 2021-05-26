# frozen_string_literal: true

module Security
  # Service for storing security reports into the database.
  #
  class StoreReportsService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
      @errors = []
    end

    def execute
      store_reports
      mark_project_as_vulnerable!
      update_latest_pipeline_id!

      errors.any? ? error(full_errors) : success
    end

    private

    attr_reader :pipeline, :errors

    delegate :project, to: :pipeline, private: true

    def store_reports
      pipeline.security_reports.reports.each do |report_type, report|
        result = StoreReportService.new(pipeline, report).execute
        errors << result[:message] if result[:status] == :error
      end
    end

    def mark_project_as_vulnerable!
      project.project_setting.update!(has_vulnerabilities: true)
    end

    def update_latest_pipeline_id!
      # We are resetting/reloading the `project` record because the `vulnerability_statistic` association
      # is created by an UPSERT query which does not set the association of the record.
      # Also, the safe navigation is necessary in case if we can't save any vulnerability records.
      project.reset.vulnerability_statistic&.update_column(:latest_pipeline_id, pipeline.id)
    end

    def full_errors
      errors.join(", ")
    end
  end
end
