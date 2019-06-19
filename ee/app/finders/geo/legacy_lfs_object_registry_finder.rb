# frozen_string_literal: true

module Geo
  class LegacyLfsObjectRegistryFinder < RegistryFinder
    def syncable
      current_node.lfs_objects.syncable
    end

    def lfs_objects_failed
      legacy_inner_join_registry_ids(
        syncable,
        Geo::FileRegistry.lfs_objects.failed.pluck_file_key,
        LfsObject
      )
    end

    def lfs_objects_unsynced(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.lfs_objects.pluck_file_key | except_file_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_file_ids,
        LfsObject
      )
    end

    def lfs_objects_migrated_local(except_file_ids:)
      legacy_inner_join_registry_ids(
        current_node.lfs_objects.with_files_stored_remotely,
        Geo::FileRegistry.lfs_objects.file_id_not_in(except_file_ids).pluck_file_key,
        LfsObject
      )
    end

    def lfs_objects_synced_missing_on_primary
      legacy_inner_join_registry_ids(
        syncable,
        Geo::FileRegistry.lfs_objects.synced.missing_on_primary.pluck_file_key,
        LfsObject
      )
    end

    def registries_for_lfs_objects
      return Geo::FileRegistry.lfs_objects unless selective_sync?

      legacy_inner_join_registry_ids(
        Geo::FileRegistry.lfs_objects,
        current_node.lfs_objects.pluck_primary_key,
        Geo::FileRegistry,
        foreign_key: :file_id
      )
    end
  end
end
