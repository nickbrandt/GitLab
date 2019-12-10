# frozen_string_literal: true

module Security
  # Service for storing security reports into the database.
  #
  class StoreReportsService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      errors = []
      @pipeline.security_reports.reports.each do |report_type, report|
        result = StoreReportService.new(@pipeline, report).execute
        errors << result[:message] if result[:status] == :error
      end

      cache_vulnerabilities

      if errors.any?
        error(errors.join(", "))
      else
        success
      end
    end

    # Silently swallow errors if there are any problems caching vulnerabilities
    def cache_vulnerabilities
      project = @pipeline.project

      Gitlab::Vulnerabilities::HistoryCache.new(project.group, project.id)
        .fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE, force: true)
    rescue => err
      error("Failed to cache vulnerabilities for pipeline #{@pipeline.id}: #{err}")
    end
  end
end
