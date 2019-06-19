# frozen_string_literal: true

module Geo
  class LegacyLfsObjectRegistryFinder < RegistryFinder
    def syncable
      current_node.lfs_objects.syncable
    end

    def lfs_objects_migrated_local(except_file_ids:)
      legacy_inner_join_registry_ids(
        current_node.lfs_objects.with_files_stored_remotely,
        Geo::FileRegistry.lfs_objects.file_id_not_in(except_file_ids).pluck_file_key,
        LfsObject
      )
    end
  end
end
