# frozen_string_literal: true

module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    # Counts all existing registries independent
    # of any change on filters / selective sync
    def count_registry
      Geo::LfsObjectRegistry.count
    end

    def count_syncable
      syncable.count
    end

    def count_synced
      lfs_objects.synced.count
    end

    def count_failed
      lfs_objects.failed.count
    end

    def count_synced_missing_on_primary
      lfs_objects.synced.missing_on_primary.count
    end

    def syncable
      return lfs_objects if selective_sync?
      return LfsObject.with_files_stored_locally if local_storage_only?

      LfsObject
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
      source_ids = lfs_objects(fdw: false).where(id: range).pluck_primary_key # rubocop:disable CodeReuse/ActiveRecord
      tracked_ids = Geo::LfsObjectRegistry.pluck_model_ids_in_range(range)

      untracked_ids = source_ids - tracked_ids
      unused_tracked_ids = tracked_ids - source_ids

      [untracked_ids, unused_tracked_ids]
    end

    # Returns LfsObjectRegistry records that have never been synced.
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
      Geo::LfsObjectRegistry
        .never
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # Deprecated in favor of the process using
    # #find_registry_differences and #find_never_synced_registries
    #
    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    # rubocop:disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_ids: [])
      lfs_objects
        .missing_registry
        .id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_ids: [])
      all_lfs_objects
        .inner_join_registry
        .with_files_stored_remotely
        .id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_ids: [])
      registries_for_lfs_objects
        .merge(Geo::LfsObjectRegistry.failed)
        .merge(Geo::LfsObjectRegistry.retry_due)
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_ids: [])
      registries_for_lfs_objects
        .synced
        .missing_on_primary
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def lfs_objects(fdw: true)
      local_storage_only?(fdw: fdw) ? all_lfs_objects(fdw: fdw).with_files_stored_locally : all_lfs_objects(fdw: fdw)
    end

    def all_lfs_objects(fdw: true)
      current_node(fdw: fdw).lfs_objects
    end

    def registries_for_lfs_objects
      current_node.lfs_object_registries
    end
  end
end
