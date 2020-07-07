# frozen_string_literal: true

module Elastic
  class MetricsUpdateService
    def execute
      return unless elasticsearch_enabled?
      return unless prometheus_enabled?

      incremental_gauge = Gitlab::Metrics.gauge(:global_search_bulk_cron_queue_size, 'Number of incremental database updates waiting to be synchronized to Elasticsearch', {}, :max)
      incremental_gauge.set({}, Elastic::ProcessBookkeepingService.queue_size)

      initial_gauge = Gitlab::Metrics.gauge(:global_search_bulk_cron_initial_queue_size, 'Number of initial database updates waiting to be synchronized to Elasticsearch', {}, :max)
      initial_gauge.set({}, Elastic::ProcessInitialBookkeepingService.queue_size)

      awaiting_indexing_gauge = Gitlab::Metrics.gauge(:global_search_awaiting_indexing_queue_size, 'Number of database updates waiting to be synchronized to Elasticsearch while indexing is paused.', {}, :max)
      awaiting_indexing_gauge.set({}, Elastic::IndexingControlService.queue_size)
    end

    private

    def elasticsearch_enabled?
      ::Gitlab::CurrentSettings.elasticsearch_indexing?
    end

    def prometheus_enabled?
      ::Gitlab::Metrics.prometheus_metrics_enabled?
    end
  end
end
