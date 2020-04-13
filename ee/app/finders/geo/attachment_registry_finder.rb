# frozen_string_literal: true

module Geo
  class AttachmentRegistryFinder < FileRegistryFinder
    # Counts all existing registries independent
    # of any change on filters / selective sync
    def count_registry
      Geo::UploadRegistry.count
    end

    def count_syncable
      syncable.count
    end

    def count_synced
      registries_for_attachments.merge(Geo::UploadRegistry.synced).count
    end

    def count_failed
      registries_for_attachments.merge(Geo::UploadRegistry.failed).count
    end

    def count_synced_missing_on_primary
      registries_for_attachments
        .merge(Geo::UploadRegistry.synced)
        .merge(Geo::UploadRegistry.missing_on_primary)
        .count
    end

    def syncable
      return attachments if selective_sync?
      return Upload.with_files_stored_locally if local_storage_only?

      Upload
    end

    # Returns untracked uploads as well as tracked uploads that are unused.
    #
    # Untracked uploads is an array where each item is a tuple of [id, file_type]
    # that is supposed supposed to be synced but don't yet have a registry entry.
    #
    # Unused uploads is an array where each item is a tuple of [id, file_type]
    # that is not supposed to be synced but already have a registry entry. For
    # example:
    #
    #   - orphaned registries
    #   - records that became excluded from selective sync
    #   - records that are in object storage, and `sync_object_storage` became
    #     disabled
    #
    # We compute both sets in this method to reduce the number of DB queries
    # performed.
    #
    # @return [Array] the first element is an Array of untracked uploads, and the
    #                 second element is an Array of tracked uploads that are unused.
    #                 For example: [[[1, 'avatar'], [5, 'file']], [[3, 'attachment']]]
    def find_registry_differences(range)
      # rubocop:disable CodeReuse/ActiveRecord
      source =
        attachments(fdw: false)
            .id_in(range)
            .pluck(::Upload.arel_table[:id], ::Upload.arel_table[:uploader])
            .map! { |id, uploader| [id, uploader.sub(/Uploader\z/, '').underscore] }

      tracked =
        Geo::UploadRegistry
            .model_id_in(range)
            .pluck(:file_id, :file_type)
      # rubocop:enable CodeReuse/ActiveRecord

      untracked = source - tracked
      unused_tracked = tracked - source

      [untracked, unused_tracked]
    end

    # Returns Geo::UploadRegistry records that have never been synced.
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
      Geo::UploadRegistry
        .never
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # Deprecated in favor of the process using
    # #find_registry_differences and #find_never_synced_registries
    #
    # Find limited amount of non replicated attachments.
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
      attachments
        .missing_registry
        .id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_ids: [])
      all_attachments
        .inner_join_registry
        .with_files_stored_remotely
        .id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_ids: [])
      Geo::UploadRegistry
        .failed
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_ids: [])
      Geo::UploadRegistry
        .synced
        .missing_on_primary
        .retry_due
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def attachments(fdw: true)
      local_storage_only?(fdw: fdw) ? all_attachments(fdw: fdw).with_files_stored_locally : all_attachments(fdw: fdw)
    end

    def all_attachments(fdw: true)
      current_node(fdw: fdw).attachments
    end

    def registries_for_attachments
      attachments.inner_join_registry
    end
  end
end
