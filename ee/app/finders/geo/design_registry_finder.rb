# frozen_string_literal: true

module Geo
  class DesignRegistryFinder < RegistryFinder
    def replicables
      current_node.designs
    end

    def registry_class
      Geo::DesignRegistry
    end
  end
end
