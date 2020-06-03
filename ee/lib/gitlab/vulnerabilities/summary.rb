# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class Summary
      attr_reader :vulnerable, :filters

      def initialize(vulnerable, params)
        @filters = params
        @vulnerable = vulnerable
      end

      def findings_counter
        return cached_vulnerability_summary if use_vulnerability_cache?

        vulnerabilities = found_vulnerabilities.counted_by_severity
        VulnerabilitySummarySerializer.new.represent(vulnerabilities)
      end

      private

      def cached_vulnerability_summary
        summary = {
          info:      0,
          unknown:   0,
          low:       0,
          medium:    0,
          high:      0,
          critical:  0
        }

        summary_keys = ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.map(&:to_sym)

        project_ids_to_fetch.each do |project_id|
          project_summary = Gitlab::Vulnerabilities::SummaryCache
            .new(vulnerable, project_id)
            .fetch

          summary_keys.each do |key|
            summary[key] += project_summary[key] unless project_summary[key].nil?
          end
        end

        summary
      end

      def found_vulnerabilities
        ::Security::VulnerabilityFindingsFinder.new(pipeline_ids, params: filters).execute
      end

      def use_vulnerability_cache?
        Feature.enabled?(:cache_vulnerability_summary) && !dynamic_filters_included?
      end

      def dynamic_filters_included?
        dynamic_filters = [:report_type, :confidence, :severity]

        filters.keys.any? { |k| dynamic_filters.include?(k.to_sym) }
      end

      def project_ids_to_fetch
        return [vulnerable.id] if vulnerable.is_a?(Project)

        if filters.key?('project_id')
          vulnerable.project_ids_with_security_reports & filters[:project_id].map(&:to_i)
        else
          vulnerable.project_ids_with_security_reports
        end
      end

      def pipeline_ids
        vulnerable.all_pipelines.with_vulnerabilities.latest_successful_ids_per_project
      end
    end
  end
end
