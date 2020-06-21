# frozen_string_literal: true

class ElasticIndexInitialBulkCronWorker
  include Elastic::BulkCronWorker

  feature_category :global_search
  idempotent!
  urgency :throttled

  private

  def service
    Gitlab::Elastic::BulkIndexer::InitialProcessor.service
  end
end
