# frozen_string_literal: true

module Geo
  class DesignRepositoryShardSyncWorker < RepositoryShardSyncWorker # rubocop:disable Scalability/IdempotentWorker
    private

    def schedule_job(project_id)
      job_id = Geo::DesignRepositorySyncWorker.perform_async(project_id)

      { project_id: project_id, job_id: job_id } if job_id
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_ids_not_synced(except_ids:, batch_size:)
      if Geo::DesignRegistry.registry_consistency_worker_enabled?
        project_ids =
          find_never_synced_project_ids(batch_size: batch_size, except_ids: except_ids)

        find_project_ids_within_shard(project_ids, direction: :desc)
      else
        Geo::DesignUnsyncedFinder
          .new(scheduled_project_ids: except_ids, shard_name: shard_name, batch_size: batch_size)
          .execute
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_ids_updated_recently(except_ids:, batch_size:)
      if Geo::DesignRegistry.registry_consistency_worker_enabled?
        project_ids =
          find_retryable_dirty_project_ids(batch_size: batch_size, except_ids: except_ids)

        find_project_ids_within_shard(project_ids, direction: :asc)
      else
        Geo::DesignUpdatedRecentlyFinder
          .new(scheduled_project_ids: except_ids, shard_name: shard_name, batch_size: batch_size)
          .execute
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_never_synced_project_ids(batch_size:, except_ids:)
      registry_finder
        .find_never_synced_registries(batch_size: batch_size, except_ids: except_ids)
        .pluck_model_foreign_key
    end

    def find_retryable_dirty_project_ids(batch_size:, except_ids:)
      registry_finder
        .find_retryable_dirty_registries(batch_size: batch_size, except_ids: except_ids)
        .pluck_model_foreign_key
    end

    def registry_finder
      @registry_finder ||= Geo::DesignRegistryFinder.new
    end
  end
end
