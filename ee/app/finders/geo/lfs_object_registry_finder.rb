# frozen_string_literal: true

module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def replicables
      local_storage_only? ? lfs_objects.with_files_stored_locally : lfs_objects
    end

    def syncable
      Geo::LfsObjectRegistry
    end

    private

    def lfs_objects
      current_node.lfs_objects
    end
  end
end
