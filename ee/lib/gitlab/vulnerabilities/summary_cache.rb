# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class SummaryCache
      attr_reader :group, :project_id

      def initialize(group, project_id)
        @group = group
        @project_id = project_id
      end

      def fetch(force: false)
        Rails.cache.fetch(cache_key, force: force, expires_in: 1.day) do
          findings = ::Security::VulnerabilityFindingsFinder
            .new(group, params: { project_id: [project_id] })
            .execute(:all)
            .counted_by_severity

          VulnerabilitySummarySerializer.new.represent(findings)
        end
      end

      private

      def cache_key
        ['projects', project_id, 'findings-summary']
      end
    end
  end
end
