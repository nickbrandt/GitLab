# frozen_string_literal: true

module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    # Counts all existing registries independent
    # of any change on filters / selective sync
    def count_registry
      Geo::JobArtifactRegistry.count
    end

    def count_syncable
      syncable.count
    end

    def count_synced
      registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.synced).count
    end

    def count_failed
      registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.failed).count
    end

    def count_synced_missing_on_primary
      registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.synced.missing_on_primary).count
    end

    def syncable
      return job_artifacts.not_expired if selective_sync?
      return Ci::JobArtifact.not_expired.with_files_stored_locally if local_storage_only?

      Ci::JobArtifact.not_expired
    end

    # Returns untracked IDs as well as tracked IDs that are unused.
    #
    # Untracked IDs are model IDs that are supposed to be synced but don't yet
    # have a registry entry.
    #
    # Unused tracked IDs are model IDs that are not supposed to be synced but
    # already have a registry entry. For example:
    #
    #   - orphaned registries
    #   - records that became excluded from selective sync
    #   - records that are in object storage, and `sync_object_storage` became
    #     disabled
    #
    # We compute both sets in this method to reduce the number of DB queries
    # performed.
    #
    # @return [Array] the first element is an Array of untracked IDs, and the second element is an Array of tracked IDs that are unused
    def find_registry_differences(range)
      # rubocop:disable CodeReuse/ActiveRecord
      source_ids =
        job_artifacts(fdw: false)
            .id_in(range)
            .pluck(::Ci::JobArtifact.arel_table[:id])
      # rubocop:enable CodeReuse/ActiveRecord

      tracked_ids =
        Geo::JobArtifactRegistry
            .pluck_model_ids_in_range(range)

      untracked_ids = source_ids - tracked_ids
      unused_tracked_ids = tracked_ids - source_ids

      [untracked_ids, unused_tracked_ids]
    end

    # Returns Geo::JobArtifactRegistry records that have never been synced.
    #
    # Does not care about selective sync, because it considers the Registry
    # table to be the single source of truth. The contract is that other
    # processes need to ensure that the table only contains records that should
    # be synced.
    #
    # Any registries that have ever been synced that currently need to be
    # resynced will be handled by other find methods (like
    # #find_retryable_failed_registries)
    #
    # You can pass a list with `except_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    # rubocop:disable CodeReuse/ActiveRecord
    def find_never_synced_registries(batch_size:, except_ids: [])
      Geo::JobArtifactRegistry
        .never
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # Deprecated in favor of the process using
    # #find_registry_differences and #find_never_synced_registries
    #
    # Find limited amount of non replicated job artifacts.
    #
    # You can pass a list with `except_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_ids: [])
      job_artifacts
        .not_expired
        .missing_job_artifact_registry
        .id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_ids: [])
      all_job_artifacts
        .inner_join_job_artifact_registry
        .with_files_stored_remotely
        .id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_ids: [])
      Geo::JobArtifactRegistry
        .failed
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_ids: [])
      Geo::JobArtifactRegistry
        .synced
        .missing_on_primary
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def job_artifacts(fdw: true)
      local_storage_only?(fdw: fdw) ? all_job_artifacts(fdw: fdw).with_files_stored_locally : all_job_artifacts(fdw: fdw)
    end

    def all_job_artifacts(fdw: true)
      current_node(fdw: fdw).job_artifacts
    end

    def registries_for_job_artifacts
      job_artifacts
        .inner_join_job_artifact_registry
        .not_expired
    end
  end
end
