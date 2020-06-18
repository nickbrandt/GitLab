# frozen_string_literal: true

module Geo
  class DesignRepositoryShardSyncWorker < RepositoryShardSyncWorker # rubocop:disable Scalability/IdempotentWorker
    private

    def schedule_job(project_id)
      job_id = Geo::DesignRepositorySyncWorker.perform_async(project_id)

      { project_id: project_id, job_id: job_id } if job_id
    end

    def find_project_ids_not_synced(except_ids:, batch_size:)
      Geo::DesignUnsyncedFinder
        .new(scheduled_project_ids: except_ids, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    def find_project_ids_updated_recently(except_ids:, batch_size:)
      Geo::DesignUpdatedRecentlyFinder
        .new(scheduled_project_ids: except_ids, shard_name: shard_name, batch_size: batch_size)
        .execute
    end
  end
end
