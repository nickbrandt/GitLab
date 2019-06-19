# frozen_string_literal: true

module Geo
  class LegacyLfsObjectRegistryFinder < RegistryFinder
    def syncable
      current_node.lfs_objects.syncable
    end
  end
end
