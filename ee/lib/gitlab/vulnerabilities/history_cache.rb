# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class HistoryCache
      attr_reader :vulnerable, :project_id

      def initialize(vulnerable, project_id)
        @vulnerable = vulnerable
        @project_id = project_id
      end

      def fetch(range, force: false)
        Rails.cache.fetch(cache_key, force: force, expires_in: 1.day) do
          findings = ::Security::VulnerabilityFindingsFinder
            .new(vulnerable, params: { project_id: [project_id] })
            .execute(:all)
            .count_by_day_and_severity(range)
          ::Vulnerabilities::HistorySerializer.new.represent(findings)
        end
      end

      private

      def cache_key
        # TODO: rename 'vulnerabilities' to 'findings' in the cache key, but carefully
        # https://gitlab.com/gitlab-org/gitlab/issues/32963
        ['projects', project_id, 'vulnerabilities']
      end
    end
  end
end
