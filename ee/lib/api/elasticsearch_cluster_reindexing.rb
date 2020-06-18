# frozen_string_literal: true

module API
  class ElasticsearchClusterReindexing < Grape::API
    before { authenticated_as_admin! }

    resource :elasticsearch_cluster_reindexing do
      desc 'Reindex elasticsearch index using reindex API' do
        detail <<~END
          This feature was introduced in GitLab 13.1.

          This will trigger elasticsearch zero-downtime cluster reindexing.

          You should have enough free disk space in your cluster.
        END
      end
      put 'trigger' do
        ElasticClusterReindexingWorker.perform_async # rubocop:disable CodeReuse/Worker
      end
    end
  end
end
