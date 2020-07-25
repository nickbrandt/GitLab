# frozen_string_literal: true

module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    def replicables
      ::Ci::JobArtifact.replicables_for_geo_node
    end

    def syncable
      Geo::JobArtifactRegistry
    end
  end
end
