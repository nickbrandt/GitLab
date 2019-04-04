# frozen_string_literal: true

module Geo
  class ProjectRegistryFinder < RegistryFinder
    def count_projects
      current_node.projects.count
    end

    def count_synced_repositories
      registries_for_synced_projects(:repository).count
    end

    def count_synced_wikis
      registries_for_synced_projects(:wiki).count
    end

    def count_failed_repositories
      registries_for_failed_projects(:repository).count
    end

    def count_failed_wikis
      registries_for_failed_projects(:wiki).count
    end

    def find_failed_project_registries(type = nil)
      registries_for_failed_projects(type)
    end

    def count_verified_repositories
      registries_for_verified_projects(:repository).count
    end

    def count_verified_wikis
      registries_for_verified_projects(:wiki).count
    end

    def count_verification_failed_repositories
      registries_for_verification_failed_projects(:repository).count
    end

    def count_verification_failed_wikis
      registries_for_verification_failed_projects(:wiki).count
    end

    def find_verification_failed_project_registries(type = nil)
      registries_for_verification_failed_projects(type)
    end

    def count_repositories_checksum_mismatch
      registries_for_mismatch_projects(:repository).count
    end

    def count_wikis_checksum_mismatch
      registries_for_mismatch_projects(:wiki).count
    end

    def find_checksum_mismatch_project_registries(type = nil)
      registries_for_mismatch_projects(type)
    end

    def count_repositories_retrying_verification
      registries_retrying_verification(:repository).count
    end

    def count_wikis_retrying_verification
      registries_retrying_verification(:wiki).count
    end

    def find_registries_to_verify(shard_name:, batch_size:)
      finder_klass_for_registries_pending_verification
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    def find_unsynced_projects(shard_name:, batch_size:)
      finder_klass_for_unsynced_projects
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    def find_projects_updated_recently(shard_name:, batch_size:)
      finder_klass_for_projects_updated_recently
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    private

    def fdw_disabled?
      !Gitlab::Geo::Fdw.enabled?
    end

    def use_legacy_queries_for_selective_sync?
      fdw_disabled? || selective_sync? && !Gitlab::Geo::Fdw.enabled_for_selective_sync?
    end

    def finder_klass_for_unsynced_projects
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectUnsyncedFinder
      else
        Geo::ProjectUnsyncedFinder
      end
    end

    def finder_klass_for_projects_updated_recently
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectUpdatedRecentlyFinder
      else
        Geo::ProjectUpdatedRecentlyFinder
      end
    end

    def finder_klass_for_synced_registries
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistrySyncedFinder
      else
        Geo::ProjectRegistrySyncedFinder
      end
    end

    def registries_for_synced_projects(type)
      finder_klass_for_synced_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_failed_registries
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistrySyncFailedFinder
      else
        Geo::ProjectRegistrySyncFailedFinder
      end
    end

    def registries_for_failed_projects(type)
      finder_klass_for_failed_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_verified_registries
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistryVerifiedFinder
      else
        Geo::ProjectRegistryVerifiedFinder
      end
    end

    def registries_for_verified_projects(type)
      finder_klass_for_verified_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_verification_failed_registries
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistryVerificationFailedFinder
      else
        Geo::ProjectRegistryVerificationFailedFinder
      end
    end

    def registries_for_verification_failed_projects(type)
      finder_klass_for_verification_failed_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_registries_retrying_verification
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistryRetryingVerificationFinder
      else
        Geo::ProjectRegistryRetryingVerificationFinder
      end
    end

    def registries_retrying_verification(type)
      finder_klass_for_registries_retrying_verification
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_mismatch_registries
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistryMismatchFinder
      else
        Geo::ProjectRegistryMismatchFinder
      end
    end

    def registries_for_mismatch_projects(type)
      finder_klass_for_mismatch_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_registries_pending_verification
      if use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistryPendingVerificationFinder
      else
        Geo::ProjectRegistryPendingVerificationFinder
      end
    end
  end
end
