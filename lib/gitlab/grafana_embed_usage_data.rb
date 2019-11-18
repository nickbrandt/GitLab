# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        count = 0
        Issue.select(:id).with_project_grafana_integration.grafana_embedded.each_batch do |issue_batch|
          count += issue_batch.count
        end

        count
      end
    end
  end
end
