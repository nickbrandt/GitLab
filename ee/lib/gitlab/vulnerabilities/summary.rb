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
          undefined: 0,
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
        ::Security::VulnerabilityFindingsFinder.new(vulnerable, params: filters).execute
      end

      def use_vulnerability_cache?
        Feature.enabled?(:cache_vulnerability_summary, vulnerable) && !dynamic_filters_included?
      end

      def dynamic_filters_included?
        dynamic_filters = [:report_type, :confidence, :severity]

        filters.keys.any? { |k| dynamic_filters.include?(k.to_sym) }
      end

      def project_ids_to_fetch
        project_ids = vulnerable.is_a?(Project) ? [vulnerable.id] : []

        return filters[:project_id] + project_ids if filters.key?('project_id')

        vulnerable.is_a?(Group) ? vulnerable.project_ids_with_security_reports : project_ids
      end
    end
  end
end
