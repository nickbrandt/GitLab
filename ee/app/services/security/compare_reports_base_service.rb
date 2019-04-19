# frozen_string_literal: true

module Security
  class CompareReportsBaseService
    attr_reader :base_report, :head_report, :report_diff

    def initialize(base_report, head_report)
      @base_report = base_report
      @head_report = head_report
      @report_diff = ::Gitlab::Ci::Reports::Security::ReportsDiff.new
    end

    def execute
      # If there is nothing to compare with, just consider all
      # head occurrences as added
      if base_report.occurrences.blank?
        report_diff.added = head_report.occurrences

        return report_diff
      end

      update_base_occurrence_locations

      report_diff.added = head_report.occurrences - base_report.occurrences
      report_diff.fixed = base_report.occurrences - head_report.occurrences
      report_diff.existing = base_report.occurrences & head_report.occurrences

      report_diff
    end

    private

    def update_base_occurrence_locations
      # Override this method with an update strategy in subclass if any?
    end
  end
end
