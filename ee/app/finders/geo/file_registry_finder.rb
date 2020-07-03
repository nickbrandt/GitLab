# frozen_string_literal: true

module Geo
  class FileRegistryFinder < RegistryFinder
    # @!method count_syncable
    #    Return a count of the registry records for the tracked file_type(s)
    def count_syncable
      syncable.count
    end

    # @!method count_synced
    #    Return a count of the registry records for the tracked file_type(s)
    #    that are synced
    def count_synced
      syncable.synced.count
    end

    # @!method count_failed
    #    Return a count of the registry records for the tracked file_type(s)
    #    that are sync failed
    def count_failed
      syncable.failed.count
    end

    # @!method count_synced_missing_on_primary
    #    Return a count of the registry records for the tracked file_type(s)
    #    that are synced and missing on the primary
    def count_synced_missing_on_primary
      syncable.synced.missing_on_primary.count
    end

    # @!method count_registry
    #    Return a count of the registry records for the tracked file_type(s)
    def count_registry
      syncable.count
    end

    # @!method find_registry_differences
    #    Returns untracked IDs as well as tracked IDs that are unused.
    #
    #    Untracked IDs are model IDs that are supposed to be synced but don't yet
    #    have a registry entry.
    #
    #    Unused tracked IDs are model IDs that are not supposed to be synced but
    #    already have a registry entry. For example:
    #
    #      - orphaned registries
    #      - records that became excluded from selective sync
    #      - records that are in object storage, and `sync_object_storage` became
    #        disabled
    #
    #    We compute both sets in this method to reduce the number of DB queries
    #    performed.
    #
    # @return [Array] the first element is an Array of untracked IDs, and the second element is an Array of tracked IDs that are unused
    def find_registry_differences(range)
      source = local_storage_only? ? replicables.with_files_stored_locally : replicables
      source_ids = source.id_in(range).pluck(replicable_primary_key) # rubocop:disable CodeReuse/ActiveRecord
      tracked_ids = syncable.pluck_model_ids_in_range(range)

      untracked_ids = source_ids - tracked_ids
      unused_tracked_ids = tracked_ids - source_ids

      [untracked_ids, unused_tracked_ids]
    end

    # @!method find_never_synced_registries
    #    Return an ActiveRecord::Relation of the registry records for the
    #    tracked file_type(s) that have never been synced.
    #
    #    Does not care about selective sync, because it considers the Registry
    #    table to be the single source of truth. The contract is that other
    #    processes need to ensure that the table only contains records that should
    #    be synced.
    #
    #    Any registries that have ever been synced that currently need to be
    #    resynced will be handled by other find methods (like
    #    #find_retryable_failed_registries)
    #
    #    You can pass a list with `except_ids:` so you can exclude items you
    #    already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    #
    # rubocop:disable CodeReuse/ActiveRecord
    def find_never_synced_registries(batch_size:, except_ids: [])
      syncable
        .never
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # @!method find_retryable_failed_registries
    #    Return an ActiveRecord::Relation of registry records marked as failed,
    #    which are ready to be retried, excluding specified IDs, limited to
    #    batch_size
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    #
    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_ids: [])
      syncable
        .failed
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # @!method find_retryable_synced_missing_on_primary_registries
    #    Return an ActiveRecord::Relation of registry records marked as synced
    #    and missing on the primary, which are ready to be retried, excluding
    #    specified IDs, limited to batch_size
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    #
    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_ids: [])
      syncable
        .synced
        .missing_on_primary
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # @!method syncable
    #    Return an ActiveRecord::Base class for the tracked file_type(s)
    def syncable
      raise NotImplementedError,
        "#{self.class} does not implement #{__method__}"
    end

    # @!method replicables
    #    Return an ActiveRecord::Relation of the replicable records for the
    #    tracked file_type(s)
    def replicables
      raise NotImplementedError,
        "#{self.class} does not implement #{__method__}"
    end

    # @!method syncable
    #    Return the fully qualified name of the replicable primary key for the
    #    tracked file_type(s)
    def replicable_primary_key
      syncable::MODEL_CLASS.arel_table[:id]
    end

    def local_storage_only?
      !current_node(fdw: false)&.sync_object_storage
    end
  end
end
