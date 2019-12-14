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

    # Find limited amount of non replicated attachments.
    #
    # You can pass a list with `except_file_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_file_ids ids that will be ignored from the query
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_file_ids: [])
      attachments
        .missing_registry
        .id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_file_ids: [])
      all_attachments
        .inner_join_registry
        .with_files_stored_remotely
        .id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_file_ids: [])
      Geo::UploadRegistry
        .failed
        .retry_due
        .file_id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_file_ids: [])
      Geo::UploadRegistry
        .synced
        .missing_on_primary
        .retry_due
        .file_id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def attachments
      local_storage_only? ? all_attachments.with_files_stored_locally : all_attachments
    end

    def all_attachments
      current_node.attachments
    end

    def registries_for_attachments
      attachments.inner_join_registry
    end
  end
end
