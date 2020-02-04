# frozen_string_literal: true

module Geo
  class ContainerRepositorySyncDispatchWorker < Geo::Scheduler::Secondary::SchedulerWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    def perform
      unless Gitlab.config.geo.registry_replication.enabled
        log_info('Container Registry replication is not enabled')
        return
      end

      super
    end

    private

    def max_capacity
      current_node.container_repositories_max_capacity
    end

    def schedule_job(repository_id)
      job_id = Geo::ContainerRepositorySyncWorker.perform_async(repository_id)

      { id: repository_id, job_id: job_id } if job_id
    end

    # Pools for new resources to be transferred
    #
    # @return [Array] resources to be transferred
    def load_pending_resources
      resources = find_unsynced_repositories(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.size

      if remaining_capacity.zero?
        resources
      else
        resources + find_retryable_failed_repositories(batch_size: remaining_capacity)
      end
    end

    def find_unsynced_repositories(batch_size:)
      Geo::ContainerRepositoryRegistryFinder
        .new(current_node_id: current_node.id)
        .find_unsynced(batch_size: batch_size, except_repository_ids: scheduled_repository_ids)
        .pluck_primary_key
    end

    def find_retryable_failed_repositories(batch_size:)
      Geo::ContainerRepositoryRegistryFinder
          .new(current_node_id: current_node.id)
          .find_retryable_failed_ids(batch_size: batch_size, except_repository_ids: scheduled_repository_ids)
    end

    def scheduled_repository_ids
      scheduled_jobs.map { |data| data[:id] }
    end
  end
end
