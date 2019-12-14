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
        .lfs_object_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_ids: [])
      registries_for_lfs_objects
        .synced
        .missing_on_primary
        .retry_due
        .lfs_object_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def lfs_objects
      local_storage_only? ? all_lfs_objects.with_files_stored_locally : all_lfs_objects
    end

    def all_lfs_objects
      current_node.lfs_objects
    end

    def registries_for_lfs_objects
      current_node.lfs_object_registries
    end
  end
end
