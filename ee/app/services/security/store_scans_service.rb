# frozen_string_literal: true

module Security
  class StoreScansService
    def initialize(build)
      @build = build
    end

    def execute
      return if @build.canceled? || @build.skipped?

      security_reports = @build.job_artifacts.security_reports

      scan_params = security_reports.map do |job_artifact|
        {
          build: @build,
          scan_type: job_artifact.file_type,
          scanned_resources_count: Gitlab::Ci::Parsers::Security::ScannedResources.new.scanned_resources_count(job_artifact)
        }
      end

      ActiveRecord::Base.transaction do
        scan_params.each do |param|
          Security::Scan.safe_find_or_create_by!(param)
        end
      end
    end
  end
end
