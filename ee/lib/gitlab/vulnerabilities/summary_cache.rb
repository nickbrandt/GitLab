# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class SummaryCache
      attr_reader :vulnerable, :project_id

      def initialize(vulnerable, project_id)
        @vulnerable = vulnerable
        @project_id = project_id
      end

      def fetch(force: false)
        Rails.cache.fetch(cache_key, force: force, expires_in: 1.day) do
          findings = ::Security::VulnerabilityFindingsFinder
            .new(pipeline_ids, params: { project_id: [project_id] })
            .execute
            .counted_by_severity

          VulnerabilitySummarySerializer.new.represent(findings)
        end
      end

      private

      def cache_key
        ['projects', project_id, 'findings-summary']
      end

      def pipeline_ids
        vulnerable.all_pipelines.with_vulnerabilities.success
      end
    end
  end
end
