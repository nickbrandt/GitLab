# frozen_string_literal: true

module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def replicables
      current_node(fdw: false).lfs_objects
    end

    def syncable
      Geo::LfsObjectRegistry
    end
  end
end
