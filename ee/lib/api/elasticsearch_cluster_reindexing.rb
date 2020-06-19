# frozen_string_literal: true

module API
  class ElasticsearchClusterReindexing < Grape::API
    before { authenticated_as_admin! }

    resource :elasticsearch_cluster_reindexing do
      desc 'Reindex elasticsearch index using reindex API' do
        detail <<~END
          This feature was introduced in GitLab 13.2.

          This will trigger elasticsearch zero-downtime cluster reindexing.

          You should have enough free disk space in your cluster.
        END
      end
      put 'trigger' do
        job_id = ElasticClusterReindexingWorker.perform_async # rubocop:disable CodeReuse/Worker

        { job_id: job_id }
      end
    end
  end
end
