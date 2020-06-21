# frozen_string_literal: true

module Elastic
  class IndexProjectsByIdService
    def execute(project_ids: [], namespace_ids: [])
      Project.id_in(project_ids).find_in_batches do |batch|
        Gitlab::Elastic::BulkIndexer::InitialProcessor.backfill_projects!(*batch)
      end

      namespace_ids.each do |namespace_id|
        ElasticNamespaceIndexerWorker.perform_async(namespace_id, :index)
      end
    end
  end
end
