# frozen_string_literal: true

module Geo
  class LegacyJobArtifactRegistryFinder < RegistryFinder
    def syncable
      current_node.job_artifacts.syncable
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

    def job_artifacts_unsynced(except_artifact_ids: [])
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck_artifact_key | except_artifact_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end

    def job_artifacts_migrated_local(except_artifact_ids: [])
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck_artifact_key - except_artifact_ids

      legacy_inner_join_registry_ids(
        current_node.job_artifacts.with_files_stored_remotely,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end

    def registries_for_job_artifacts
      return Geo::JobArtifactRegistry.all unless selective_sync?

      legacy_inner_join_registry_ids(
        Geo::JobArtifactRegistry.all,
        current_node.job_artifacts.pluck_primary_key,
        Geo::JobArtifactRegistry,
        foreign_key: :artifact_id
      )
    end
  end
end
