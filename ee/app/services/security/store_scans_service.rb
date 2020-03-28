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
        security_reports.each do |report|
          Security::Scan.safe_find_or_create_by!(
            build: @build,
            scan_type: report.file_type
          )
        end
      end
    end
  end
end
