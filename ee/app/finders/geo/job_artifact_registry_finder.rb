# frozen_string_literal: true

module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    def replicables
      current_node(fdw: false).job_artifacts.not_expired
    end

    def syncable
      Geo::JobArtifactRegistry
    end
  end
end
