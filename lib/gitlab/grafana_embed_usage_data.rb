# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        Issue.with_project_grafana_integration.where(
          Issue.arel_table[:description_html].matches('%data-dashboard-url%')
        ).count
      end
    end
  end
end
