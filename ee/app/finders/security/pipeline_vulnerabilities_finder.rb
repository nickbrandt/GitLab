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
    attr_accessor :params
    attr_reader :pipeline

    def initialize(pipeline:, params: default_params)
      @pipeline = pipeline
      @params = params
    end

    def execute
      pipeline_reports.each_with_object([]) do |(type, report), occurrences|
        next unless requested_type?(report.type)

        occurrences.concat(
          normalize_report_occurrences(report.occurrences)
        )
      end
    end

    private

    def pipeline_reports
      pipeline.security_reports.reports
    end

    def normalize_report_occurrences(report_occurrences)
      report_occurrences.map do |report_occurrence|
        occurrence_hash = report_occurrence.to_hash
          .except(:compare_key, :identifiers, :location, :scanner) # rubocop:disable CodeReuse/ActiveRecord

        occurrence = Vulnerabilities::Occurrence.new(occurrence_hash)

        occurrence.project = pipeline.project
        occurrence.build_scanner(report_occurrence.scanner.to_hash)
        occurrence.identifiers = report_occurrence.identifiers.map do |identifier|
          Vulnerabilities::Identifier.new(identifier.to_hash)
        end

        occurrence
      end
    end

    def requested_type?(type)
      Array(params[:report_type]).include?(type)
    end

    def default_params
      { report_type: Vulnerabilities::Occurrence.report_types.keys }
    end
  end
end
