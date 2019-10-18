# frozen_string_literal: true

# Security::PipelineVulnerabilitiesFinder
#
# Used to retrieve security vulnerabilities from an associated Pipeline,
# This involves normalizing Report::Occurrence POROs to Vulnerabilities::Occurrence
#
# Arguments:
#   pipeline - object to filter vulnerabilities
#   params:
#     report_type: Array<String>

module Security
  class PipelineVulnerabilitiesFinder
    include Gitlab::Utils::StrongMemoize
    ParseError = Class.new(Gitlab::Ci::Parsers::ParserError)

    attr_accessor :params
    attr_reader :pipeline

    def initialize(pipeline:, params: {})
      @pipeline = pipeline
      @params = params
    end

    def execute
      reports = pipeline_reports

      return [] if reports.nil?

      occurrences = reports.each_with_object([]) do |(type, report), occurrences|
        next unless requested_type?(type)

        raise ParseError, 'JSON parsing failed' if report.error.is_a?(Gitlab::Ci::Parsers::Security::Common::SecurityReportParserError)

        normalized_occurrences = normalize_report_occurrences(report.occurrences)
        filtered_occurrences = filter(normalized_occurrences)

        occurrences.concat(filtered_occurrences)
      end

      occurrences.sort_by { |x| [x.severity, x.confidence] }
    end

    private

    def pipeline_reports
      pipeline&.security_reports&.reports
    end

    def normalize_report_occurrences(report_occurrences)
      report_occurrences.map do |report_occurrence|
        occurrence_hash = report_occurrence.to_hash
          .except(:compare_key, :identifiers, :location, :scanner)

        occurrence = Vulnerabilities::Occurrence.new(occurrence_hash)

        occurrence.project = pipeline.project
        occurrence.build_scanner(report_occurrence.scanner.to_hash)
        occurrence.identifiers = report_occurrence.identifiers.map do |identifier|
          Vulnerabilities::Identifier.new(identifier.to_hash)
        end

        occurrence
      end
    end

    def filter(occurrences)
      occurrences.select do |occurrence|
        next if !include_dismissed? && dismissal_feedback?(occurrence)
        next unless confidence_levels.include?(occurrence.confidence)
        next unless severity_levels.include?(occurrence.severity)

        occurrence
      end
    end

    def requested_type?(type)
      report_types.include?(type)
    end

    def include_dismissed?
      params[:scope] == 'all'
    end

    def dismissal_feedback?(occurrence)
      dismissal_feedback_by_fingerprint[occurrence.project_fingerprint]
    end

    def dismissal_feedback_by_fingerprint
      strong_memoize(:dismissal_feedback_by_fingerprint) do
        pipeline.project.vulnerability_feedback
          .with_associations
          .where(feedback_type: 'dismissal') # rubocop:disable CodeReuse/ActiveRecord
          .group_by(&:project_fingerprint)
      end
    end

    def confidence_levels
      Array(params.fetch(:confidence, Vulnerabilities::Occurrence.confidences.keys))
    end

    def report_types
      Array(params.fetch(:report_type, Vulnerabilities::Occurrence.report_types.keys))
    end

    def severity_levels
      Array(params.fetch(:severity, Vulnerabilities::Occurrence.severities.keys))
    end
  end
end
