# frozen_string_literal: true

module Geo
  class AttachmentRegistryFinder < FileRegistryFinder
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
        replicables
            .id_in(range)
            .pluck(::Upload.arel_table[:id], ::Upload.arel_table[:uploader])
            .map! { |id, uploader| [id, uploader.sub(/Uploader\z/, '').underscore] }

      tracked =
        syncable
            .model_id_in(range)
            .pluck(:file_id, :file_type)
      # rubocop:enable CodeReuse/ActiveRecord

      untracked = source - tracked
      unused_tracked = tracked - source

      [untracked, unused_tracked]
    end

    def replicables
      current_node(fdw: false).attachments
    end

    def syncable
      Geo::UploadRegistry
    end
  end
end
