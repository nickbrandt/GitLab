# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    class HistoryCache
      attr_reader :group, :project_id

      def initialize(group, project_id)
        @group = group
        @project_id = project_id
      end

      def fetch(range, force: false)
        Rails.cache.fetch(cache_key, force: force, expires_in: 1.day) do
          vulnerabilities = ::Security::VulnerabilitiesFinder
            .new(group, params: { project_id: [project_id] })
            .execute(:all)
            .count_by_day_and_severity(range)
          ::Vulnerabilities::HistorySerializer.new.represent(vulnerabilities)
        end
      end

      private

      def cache_key
        ['projects', project_id, 'vulnerabilities']
      end
    end
  end
end
