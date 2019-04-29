# frozen_string_literal: true

module Geo
  class LegacyJobArtifactRegistryFinder < RegistryFinder
    def syncable
      job_artifacts.syncable
    end

    def job_artifacts
      if selective_sync?
        Ci::JobArtifact.project_id_in(current_node.projects)
      else
        Ci::JobArtifact.all
      end
    end

    def job_artifacts_synced
      legacy_inner_join_registry_ids(
        syncable,
        Geo::JobArtifactRegistry.synced.pluck_artifact_key,
        Ci::JobArtifact
      )
    end

    def job_artifacts_failed
      legacy_inner_join_registry_ids(
        syncable,
        Geo::JobArtifactRegistry.failed.pluck_artifact_key,
        Ci::JobArtifact
      )
    end

    def job_artifacts_synced_missing_on_primary
      legacy_inner_join_registry_ids(
        syncable,
        Geo::JobArtifactRegistry.synced.missing_on_primary.pluck_artifact_key,
        Ci::JobArtifact
      )
    end

    def registries_for_job_artifacts
      return Geo::JobArtifactRegistry.all unless selective_sync?

      legacy_inner_join_registry_ids(
        Geo::JobArtifactRegistry.all,
        job_artifacts.pluck_primary_key,
        Geo::JobArtifactRegistry,
        foreign_key: :artifact_id
      )
    end
  end
end
