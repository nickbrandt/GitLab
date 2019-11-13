# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        Issue.with_project_grafana_integration.find_each.count do |issue|
          has_grafana_url?(issue)
        end
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
