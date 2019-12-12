# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class Summary
      attr_reader :group, :filters

      def initialize(group, params)
        @filters = params
        @group = group
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
            .new(group, project_id)
            .fetch

          summary_keys.each do |key|
            summary[key] += project_summary[key] unless project_summary[key].nil?
          end
        end

        summary
      end

      def found_vulnerabilities
        ::Security::VulnerabilityFindingsFinder.new(group, params: filters).execute
      end

      def use_vulnerability_cache?
        Feature.enabled?(:cache_vulnerability_summary, group) && !dynamic_filters_included?
      end

      def dynamic_filters_included?
        dynamic_filters = [:report_type, :confidence, :severity]

        filters.keys.any? { |k| dynamic_filters.include?(k.to_sym) }
      end

      def project_ids_to_fetch
        return filters[:project_id] if filters.key?('project_id')

        group.project_ids_with_security_reports
      end
    end
  end
end
