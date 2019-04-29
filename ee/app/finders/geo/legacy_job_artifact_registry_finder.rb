# frozen_string_literal: true

module Geo
  class LegacyJobArtifactRegistryFinder < RegistryFinder
    def syncable
      job_artifacts.geo_syncable
    end

    def job_artifacts
      if selective_sync?
        Ci::JobArtifact.project_id_in(current_node.projects)
      else
        Ci::JobArtifact.all
      end
    end
  end
end
