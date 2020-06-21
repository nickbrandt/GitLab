# frozen_string_literal: true

module Elastic
  class MetricsUpdateService
    METRICS = {
      global_search_bulk_project_initial_queue_size: [
        ::Gitlab::Elastic::BulkIndexer::InitialProcessor,
        'Number of initial database updates waiting to be synchronized to Elasticsearch'
      ],
      global_search_bulk_project_incremental_queue_size: [
        ::Gitlab::Elastic::BulkIndexer::IncrementalProcessor,
        'Number of incremental database updates waiting to be synchronized to Elasticsearch'
      ],

      global_search_bulk_repository_initial_queue_size: [
        ::Gitlab::Elastic::Indexer::InitialProcessor,
        'Number of initial repository updates waiting to be synchronized to Elasticsearch'
      ],
      global_search_bulk_repository_incremental_queue_size: [
        ::Gitlab::Elastic::Indexer::IncrementalProcessor,
        'Number of incremental repository updates waiting to be synchronized to Elasticsearch'
      ],

      global_search_bulk_wiki_initial_queue_size: [
        ::Gitlab::Elastic::WikiIndexer::InitialProcessor,
        'Number of initial wiki updates waiting to be synchronized to Elasticsearch'
      ],
      global_search_bulk_wiki_incremental_queue_size: [
        ::Gitlab::Elastic::WikiIndexer::IncrementalProcessor,
        'Number of incremental wiki updates waiting to be synchronized to Elasticsearch'
      ]
    }.freeze

    def execute
      return unless elasticsearch_enabled?
      return unless prometheus_enabled?

      METRICS.each do |key, definition|
        processor, message = definition

        gauge = Gitlab::Metrics.gauge(key, message, {}, :max)
        gauge.set({}, Elastic::ProcessBookkeepingService.queue_size(processor: processor))
      end
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
