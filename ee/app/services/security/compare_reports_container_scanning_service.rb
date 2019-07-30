# frozen_string_literal: true

module Security
  class CompareReportsContainerScanningService
    attr_reader :base_report, :head_report, :report_diff, :serializer_class, :serializer_params

    def initialize(base_report, head_report, serializer_class, serializer_params: {})
      @base_report = base_report
      @head_report = head_report
      @serializer_class = serializer_class
      @serializer_params = serializer_params
      @report_diff = ::Gitlab::Ci::Reports::Security::ReportsDiff.new
    end

    def generate_report
      # If there is nothing to compare with, just consider all
      # head occurrences as added
      if base_report.occurrences.blank?
        report_diff.added = head_report.occurrences
      end

      report_diff.added = head_report.occurrences - base_report.occurrences
      report_diff.fixed = base_report.occurrences - head_report.occurrences
      report_diff.existing = base_report.occurrences & head_report.occurrences

      report_diff
    end

    def execute
      {
        status: :parsed,
        data: serializer_class
          .new(**serializer_params)
          .represent(generate_report).as_json
      }
    rescue Gitlab::Ci::Parsers::ParserError => e
      {
        status: :error,
        status_reason: e.message
      }
    end
  end
end
