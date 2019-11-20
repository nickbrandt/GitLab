# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        # rubocop:disable CodeReuse/ActiveRecord
        Issue.joins(project: :grafana_integration)
          .merge(Project.with_grafana_integration_enabled)
          .where("issues.description LIKE '%' || grafana_integrations.grafana_url || '%'")
          .count
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
