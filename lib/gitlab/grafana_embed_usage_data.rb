# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        count = 0

        Issue.with_project_grafana_integration.find_each do |issue|
          count += has_grafana_url?(issue) ? 1 : 0
        end

        count
      end

      private

      def has_grafana_url?(issue)
        html = Banzai.render(issue.description, project: issue.project)
        result = Banzai::Filter::InlineGrafanaMetricsFilter.new(
          html, { project: issue.project }
        ).call
        metric_node = result.at_css('.js-render-metrics')
        metric_node ? metric_node&.attribute('data-dashboard-url').to_s : nil
      end
    end
  end
end
