# frozen_string_literal: true

module Geo
  class LegacyAttachmentRegistryFinder < RegistryFinder
    def syncable
      attachments.syncable
    end

    def attachments_migrated_local(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.attachments.pluck_file_key - except_file_ids

      legacy_inner_join_registry_ids(
        attachments.with_files_stored_remotely,
        registry_file_ids,
        Upload
      )
    end

    def attachments_unsynced(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.attachments.pluck_file_key | except_file_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_file_ids,
        Upload
      )
    end

    private

    def attachments
      current_node.attachments
    end
  end
end
