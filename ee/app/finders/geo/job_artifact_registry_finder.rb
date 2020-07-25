# frozen_string_literal: true

module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    def replicables
      # TODO move not_expired into replicables scope
      ::Ci::JobArtifact.replicables_for_geo_node.not_expired
    end

    def syncable
      Geo::JobArtifactRegistry
    end
  end
end
