# frozen_string_literal: true

module Security
  class StoreScansService
    def initialize(build)
      @build = build
    end

    def execute
      return if build.canceled? || build.skipped?

      ActiveRecord::Base.transaction do
        security_reports.each { |report| create_or_update_scan_for!(report) }
      end
    end

    private

    attr_reader :build

    def security_reports
      ::Gitlab::Ci::Reports::Security::Reports.new(self).tap do |security_reports|
        build.collect_security_reports!(security_reports)
      end
    end

    def create_or_update_scan_for!(report)
      Security::Scan.safe_find_or_create_by!(build: build, scan_type: report.type) { |scan| scan.assign_attributes(severity_stats: report.severity_stats) }
                    .tap { |scan| scan.update(severity_stats: report.severity_stats) }
    end
  end
end
