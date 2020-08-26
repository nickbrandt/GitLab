# frozen_string_literal: true

module Geo
  class ContainerRepositoryRegistryFinder < RegistryFinder
    def replicables
      current_node.container_repositories
    end

    def registry_class
      Geo::ContainerRepositoryRegistry
    end
  end
end
