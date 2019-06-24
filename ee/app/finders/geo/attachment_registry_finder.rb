# frozen_string_literal: true

module Geo
  class AttachmentRegistryFinder < FileRegistryFinder
    def count_registry
      Geo::FileRegistry.attachments.count
    end

    def count_syncable
      syncable.count
    end

    def count_synced
      registries_for_attachments.syncable.merge(Geo::FileRegistry.synced).count
    end

    def count_failed
      registries_for_attachments.syncable.merge(Geo::FileRegistry.failed).count
    end

    def count_synced_missing_on_primary
      registries_for_attachments
        .syncable
        .merge(Geo::FileRegistry.synced)
        .merge(Geo::FileRegistry.missing_on_primary)
        .count
    end

    def syncable
      if selective_sync?
        attachments.syncable
      else
        Upload.syncable
      end
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
        .missing_file_registry
        .syncable
        .id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_file_ids: [])
      attachments
        .inner_join_file_registry
        .with_files_stored_remotely
        .merge(Geo::FileRegistry.attachments)
        .id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_file_ids: [])
      Geo::FileRegistry
        .attachments
        .failed
        .retry_due
        .file_id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_file_ids: [])
      Geo::FileRegistry
        .attachments
        .synced
        .missing_on_primary
        .retry_due
        .file_id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def attachments
      current_node.attachments
    end

    def registries_for_attachments
      attachments.inner_join_file_registry.merge(Geo::FileRegistry.attachments)
    end
  end
end
