# frozen_string_literal: true

module Geo
  class JobArtifactRegistryFinder < RegistryFinder
    def count_syncable
      syncable.count
    end

    def count_synced
      job_artifacts_synced.count
    end

    def count_failed
      job_artifacts_failed.count
    end

    def count_synced_missing_on_primary
      job_artifacts_synced_missing_on_primary.count
    end

    def count_registry
      registries_for_job_artifacts.count
    end

    def syncable
      if use_legacy_queries_for_selective_sync?
        legacy_finder.syncable
      elsif selective_sync?
        fdw_geo_node.job_artifacts.syncable
      else
        Ci::JobArtifact.syncable
      end
    end

    # Find limited amount of non replicated job artifacts.
    #
    # You can pass a list with `except_artifact_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_artifact_ids ids that will be ignored from the query
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_artifact_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced(except_artifact_ids: except_artifact_ids)
        else
          fdw_find_unsynced(except_artifact_ids: except_artifact_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_artifact_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local(except_artifact_ids: except_artifact_ids)
        else
          fdw_find_migrated_local(except_artifact_ids: except_artifact_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_artifact_ids: [])
      Geo::JobArtifactRegistry
        .failed
        .retry_due
        .artifact_id_not_in(except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_artifact_ids: [])
      Geo::JobArtifactRegistry
        .synced
        .missing_on_primary
        .retry_due
        .artifact_id_not_in(except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # rubocop:disable CodeReuse/Finder
    def legacy_finder
      @legacy_finder ||= Geo::LegacyJobArtifactRegistryFinder.new(current_node: current_node)
    end
    # rubocop:enable CodeReuse/Finder

    def fdw_geo_node
      @fdw_geo_node ||= Geo::Fdw::GeoNode.find(current_node.id)
    end

    def registries_for_job_artifacts
      if use_legacy_queries_for_selective_sync?
        legacy_finder.registries_for_job_artifacts
      else
        fdw_geo_node
          .job_artifacts
          .inner_join_job_artifact_registry
          .syncable
      end
    end

    def job_artifacts_synced
      if use_legacy_queries_for_selective_sync?
        legacy_finder.job_artifacts_synced
      else
        registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.synced)
      end
    end

    def job_artifacts_failed
      if use_legacy_queries_for_selective_sync?
        legacy_finder.job_artifacts_failed
      else
        registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.failed)
      end
    end

    def job_artifacts_synced_missing_on_primary
      if use_legacy_queries_for_selective_sync?
        legacy_finder.job_artifacts_synced_missing_on_primary
      else
        registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.synced.missing_on_primary)
      end
    end

    def fdw_find_unsynced(except_artifact_ids:)
      fdw_geo_node
        .job_artifacts
        .syncable
        .missing_job_artifact_registry
        .id_not_in(except_artifact_ids)
    end

    def fdw_find_migrated_local(except_artifact_ids:)
      fdw_geo_node
        .job_artifacts
        .inner_join_job_artifact_registry
        .with_files_stored_remotely
        .id_not_in(except_artifact_ids)
    end

    def legacy_find_unsynced(except_artifact_ids:)
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck_artifact_key | except_artifact_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end

    def legacy_find_migrated_local(except_artifact_ids:)
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck_artifact_key - except_artifact_ids

      legacy_inner_join_registry_ids(
        current_node.job_artifacts.with_files_stored_remotely,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end
  end
end
