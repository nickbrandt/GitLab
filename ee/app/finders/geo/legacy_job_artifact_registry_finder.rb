# frozen_string_literal: true

module Geo
  class LegacyJobArtifactRegistryFinder < RegistryFinder
    def syncable
      current_node.job_artifacts.syncable
    end
  end
end
