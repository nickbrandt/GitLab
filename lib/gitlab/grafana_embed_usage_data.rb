# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        Issue.with_project_grafana_integration.grafana_embedded.count
      end
    end
  end
end
