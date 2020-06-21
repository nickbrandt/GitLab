# frozen_string_literal: true

class ElasticIndexBulkBlobCronWorker
  include Elastic::BulkCronWorker

  feature_category :global_search
  idempotent!
  urgency :throttled

  private

  def services
    {
      repository:          Gitlab::Elastic::Indexer::IncrementalProcessor.service,
      repository_initial:  Gitlab::Elastic::Indexer::InitialProcessor.service,
      wiki:                Gitlab::Elastic::WikiIndexer::IncrementalProcessor.service,
      wiki_initial:        Gitlab::Elastic::WikiIndexer::InitialProcessor.service
    }
  end

  def logger
    Elastic::IndexingControl.logger
  end
end
