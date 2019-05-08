# frozen_string_literal: true

module Elastic
  class IndexProjectsByIdService
    def execute(project_ids: [], namespace_ids: [])
      queue_name = ElasticFullIndexWorker.queue

      project_ids.each do |project_id|
        ElasticIndexerWorker
          .set(queue: queue_name)
          .perform_async(:index, 'Project', project_id, nil)
      end

      namespace_ids.each do |namespace_id|
        ElasticNamespaceIndexerWorker
          .set(queue: queue_name)
          .perform_async(namespace_id, :index)
      end
    end
  end
end
