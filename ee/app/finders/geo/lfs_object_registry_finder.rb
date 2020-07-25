# frozen_string_literal: true

module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def replicables
      lfs_objects = current_node(fdw: false).lfs_objects

      local_storage_only? ? lfs_objects.with_files_stored_locally : lfs_objects
    end

    def syncable
      Geo::LfsObjectRegistry
    end
  end
end
