# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class OccurrenceCache
      attr_reader :vulnerable, :project_id, :user

      def initialize(vulnerable, project_id, user)
        @vulnerable = vulnerable
        @project_id = project_id
        @user = user
      end

      def fetch(force: false)
        Rails.cache.fetch(cache_key, force: force, expires_in: 1.day) do
          findings = ::Security::VulnerabilityFindingsFinder
            .new(vulnerable, params: { project_id: [project_id] })
            .execute(:with_sha)

          ::Vulnerabilities::OccurrenceSerializer
            .new(current_user: user)
            .represent(findings, preload: true)
        end
      end

      private

      def cache_key
        ['project', project_id, 'findings-occurrence']
      end
    end
  end
end
