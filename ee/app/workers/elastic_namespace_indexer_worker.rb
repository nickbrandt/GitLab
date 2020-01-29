# frozen_string_literal: true

class ElasticNamespaceIndexerWorker
  include ApplicationWorker

  feature_category :search
  sidekiq_options retry: 2

  def perform(namespace_id, operation)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?
    return true unless Gitlab::CurrentSettings.elasticsearch_limit_indexing?

    namespace = Namespace.find(namespace_id)

    case operation.to_s
    when /index/
      index_projects(namespace)
    when /delete/
      delete_from_index(namespace)
    end
  end

  private

  def index_projects(namespace)
    # The default of 1000 is good for us since Sidekiq documentation doesn't recommend more than 1000 per batch call
    # https://www.rubydoc.info/github/mperham/sidekiq/Sidekiq%2FClient:push_bulk
    namespace.all_projects.find_in_batches do |batch|
      args = batch.map { |project| [:index, project.class.to_s, project.id, project.es_id] }
      ElasticIndexerWorker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
    end
  end

  def delete_from_index(namespace)
    namespace.all_projects.find_in_batches do |batch|
      args = batch.map { |project| [:delete, project.class.to_s, project.id, project.es_id] }
      ElasticIndexerWorker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
    end
  end
end
