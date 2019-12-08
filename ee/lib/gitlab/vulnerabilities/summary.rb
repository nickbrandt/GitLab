# frozen_string_literal: true

module GitLab
  module Vulnerabilities
    class Summary
      attr_reader :group, :filters

      def initialize(group, params)
        @filters = params.permit(:scope, report_type: [], confidence: [], project_id: [], severity: [])
        @group = group
      end

      def vulnerabilities_counter
        return cached_vulnerability_summary if use_vulnerability_cache?

        vulnerabilities = found_vulnerabilities.counted_by_severity

        VulnerabilitySummarySerializer.new.represent(vulnerabilities)
      end

      private

      def cached_vulnerability_summary
        summary = {} # TODO what are the keys?

        project_ids_to_fetch.each do |project_id|
          project_summary = Gitlab::Vulnerabilities::SummaryCache
            .new(group, project_id)
            .fetch

          summary_keys = ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.map(&:to_sym) # TODO sakto ba?
          summary_keys << :total # TODO kinahanglan pa ba?
          summary_keys.each do |key|
            summary[key].merge!(project_summary[key]) do |k, aggregate, project_count|
              aggregate + project_count
            end
          end
        end

        summary[:total] = summary[:total].sort_by { |date, count| date }.to_h # TODO what is this???
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
