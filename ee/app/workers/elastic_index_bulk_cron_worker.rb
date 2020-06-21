# frozen_string_literal: true

class ElasticIndexBulkCronWorker
  include Elastic::BulkCronWorker

  feature_category :global_search
  idempotent!
  urgency :throttled

  private

  def service
    Gitlab::Elastic::BulkIndexer::IncrementalProcessor.service
  end

  def logger
    ::Gitlab::Elasticsearch::Logger.build
  end
end
