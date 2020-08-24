# frozen_string_literal: true

module Geo
  class FileRegistryFinder < RegistryFinder
    # @!method count_synced_missing_on_primary
    #    Return a count of the registry records for the tracked file_type(s)
    #    that are synced and missing on the primary
    def count_synced_missing_on_primary
      registry_class.synced.missing_on_primary.count
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
      registry_class
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
      registry_class
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
      registry_class
        .synced
        .missing_on_primary
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def local_storage_only?
      !current_node&.sync_object_storage
    end
  end
end
