# frozen_string_literal: true

module Geo
  class DesignRepositoryShardSyncWorker < RepositoryShardSyncWorker
    private

    def schedule_job(project_id)
      job_id = Geo::DesignRepositorySyncWorker.perform_async(project_id)

      { project_id: project_id, job_id: job_id } if job_id
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_ids_not_synced(batch_size:)
      find_unsynced_projects(batch_size: batch_size)
        .id_not_in(scheduled_project_ids)
        .reorder(last_repository_updated_at: :desc)
        .pluck_primary_key
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_unsynced_projects(batch_size:)
      Geo::DesignUnsyncedFinder
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_ids_updated_recently(batch_size:)
      find_projects_updated_recently(batch_size: batch_size)
        .id_not_in(scheduled_project_ids)
        .order('design_registry.last_synced_at ASC NULLS FIRST')
        .pluck_primary_key
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_projects_updated_recently(batch_size:)
      Geo::DesignUpdatedRecentlyFinder
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end
  end
end
