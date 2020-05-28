# frozen_string_literal: true

module Gitlab
  module Metrics
    # Rack middleware for tracking Elasticsearch metrics from Grape and Web requests.
    class ElasticsearchRackMiddleware
      HISTOGRAM_BUCKETS = [0.1, 0.25, 0.5, 1, 2.5, 5, 10, 60].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        transaction = Gitlab::Metrics.current_transaction

        @app.call(env)
      ensure
        record_metrics(transaction) if transaction
      end

      private

      def record_metrics(transaction)
        labels = transaction.labels
        query_time = ::Gitlab::Instrumentation::ElasticsearchTransport.query_time
        request_count = ::Gitlab::Instrumentation::ElasticsearchTransport.get_request_count

        Gitlab::Metrics.counter(:http_elasticsearch_requests_total,
                                'Amount of calls to Elasticsearch servers during web requests',
                                Gitlab::Metrics::Transaction::BASE_LABELS).increment(labels, request_count)

        Gitlab::Metrics.histogram(:http_elasticsearch_requests_duration_seconds,
                                  'Query time for Elasticsearch servers during web requests',
                                  Gitlab::Metrics::Transaction::BASE_LABELS,
                                  HISTOGRAM_BUCKETS).observe(labels, query_time)
      end
    end
  end
end
