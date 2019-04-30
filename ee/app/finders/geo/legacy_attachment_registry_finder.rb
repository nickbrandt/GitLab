# frozen_string_literal: true

module Geo
  class LegacyAttachmentRegistryFinder < RegistryFinder
    def syncable
      attachments.syncable
    end

    def attachments_synced
      legacy_inner_join_registry_ids(
        syncable,
        Geo::FileRegistry.attachments.synced.pluck_file_key,
        Upload
      )
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

    def attachments_failed
      legacy_inner_join_registry_ids(
        syncable,
        Geo::FileRegistry.attachments.failed.pluck_file_key,
        Upload
      )
    end

    def attachments_synced_missing_on_primary
      legacy_inner_join_registry_ids(
        syncable,
        Geo::FileRegistry.attachments.synced.missing_on_primary.pluck_file_key,
        Upload
      )
    end

    def registries_for_attachments
      return Geo::FileRegistry.attachments unless selective_sync?

      legacy_inner_join_registry_ids(
        Geo::FileRegistry.attachments,
        attachments.pluck_primary_key,
        Geo::FileRegistry,
        foreign_key: :file_id
      )
    end

    private

    def attachments
      current_node.attachments
    end
  end
end
