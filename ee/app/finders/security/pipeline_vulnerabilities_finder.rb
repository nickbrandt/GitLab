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

        normalized_occurrences = normalize_report_occurrences(
          report.occurrences,
          vulnerabilities_by_finding_fingerprint(type, report))
        filtered_occurrences = filter(normalized_occurrences)

        occurrences.concat(filtered_occurrences)
      end

      sort_occurrences(occurrences)
    end

    private

    def sort_occurrences(occurrences)
      # This sort is stable (see https://en.wikipedia.org/wiki/Sorting_algorithm#Stability) contrary to the bare
      # Ruby sort_by method. Using just sort_by leads to instability across different platforms (e.g., x86_64-linux and
      # x86_64-darwin18) which in turn leads to different sorting results for the equal elements across these platforms.
      # This is important because it breaks test suite results consistency between local and CI
      # environment.
      # This is easier to address from within the class rather than from tests because this leads to bad class design
      # and exposing too much of its implementation details to the test suite.
      # See also https://stackoverflow.com/questions/15442298/is-sort-in-ruby-stable.
      stable_sort_by(occurrences) { |x| [-x.severity_value, -x.confidence_value] }
    end

    def stable_sort_by(occurrences)
      occurrences.sort_by.with_index { |x, idx| [yield(x), idx] }
    end

    def pipeline_reports
      pipeline&.security_reports&.reports
    end

    def vulnerabilities_by_finding_fingerprint(report_type, report)
      Vulnerabilities::Occurrence
        .with_vulnerabilities_for_state(
          project: pipeline.project,
          report_type: report_type,
          project_fingerprints: report.occurrences.map(&:project_fingerprint))
       .each_with_object({}) do |occurrence, hash|
        hash[occurrence.project_fingerprint] = occurrence.vulnerability
      end
    end

    def normalize_report_occurrences(report_occurrences, vulnerabilities)
      report_occurrences.map do |report_occurrence|
        occurrence_hash = report_occurrence.to_hash
          .except(:compare_key, :identifiers, :location, :scanner)

        occurrence = Vulnerabilities::Occurrence.new(occurrence_hash)
        # assigning Vulnerabilities to Findings to enable the computed state
        occurrence.location_fingerprint = report_occurrence.location.fingerprint
        occurrence.vulnerability = vulnerabilities[occurrence.project_fingerprint]
        occurrence.project = pipeline.project
        occurrence.sha = pipeline.sha
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
