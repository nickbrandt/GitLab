# frozen_string_literal: true

module Security
  class StoreScansService
    def initialize(build)
      @build = build
    end

    def execute
      return if @build.canceled? || @build.skipped?

      security_reports = @build.job_artifacts.security_reports

      ActiveRecord::Base.transaction do
        @build.each_report(::Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES) do |file_type, blob, artifact|
          job_artifact_json = JSON.parse(blob)
          Security::Scan.safe_find_or_create_by!(
            build: @build,
            scan_type: file_type,
            scanned_resources_count: job_artifact_json['scan']['scanned_resources'].length()
          )
        end
      end
    end
  end
end
