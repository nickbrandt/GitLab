# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        get_embed_count
      end

      private

      def get_embed_count
        Issue.class_eval { include EachBatch } unless Issue < EachBatch

        count = 0
        Issue.each_batch do |issue_batch|
          embed_count_per_batch = issue_batch.map do |issue|
            has_grafana_url?(issue)
          end.count(&:itself)
          count += embed_count_per_batch
        end

        count
      end

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
