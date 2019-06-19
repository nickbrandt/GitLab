# frozen_string_literal: true

module Geo
  class LegacyJobArtifactRegistryFinder < RegistryFinder
    def syncable
      current_node.job_artifacts.syncable
    end

    def job_artifacts_migrated_local(except_artifact_ids: [])
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck_artifact_key - except_artifact_ids

      legacy_inner_join_registry_ids(
        current_node.job_artifacts.with_files_stored_remotely,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end
  end
end
