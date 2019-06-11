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
      Geo::ProjectRegistryPendingVerificationFinder
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    def find_unsynced_projects(shard_name:, batch_size:)
      Geo::ProjectUnsyncedFinder
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    def find_projects_updated_recently(shard_name:, batch_size:)
      Geo::ProjectUpdatedRecentlyFinder
        .new(current_node: current_node, shard_name: shard_name, batch_size: batch_size)
        .execute
    end

    private

    def registries_for_synced_projects(type)
      Geo::ProjectRegistrySyncedFinder
        .new(current_node: current_node, type: type)
        .execute
    end

    def registries_for_failed_projects(type)
      Geo::ProjectRegistrySyncFailedFinder
        .new(current_node: current_node, type: type)
        .execute
    end

    def registries_for_verified_projects(type)
      Geo::ProjectRegistryVerifiedFinder
        .new(current_node: current_node, type: type)
        .execute
    end

    def registries_for_verification_failed_projects(type)
      Geo::ProjectRegistryVerificationFailedFinder
        .new(current_node: current_node, type: type)
        .execute
    end

    def registries_retrying_verification(type)
      Geo::ProjectRegistryRetryingVerificationFinder
        .new(current_node: current_node, type: type)
        .execute
    end

    def registries_for_mismatch_projects(type)
      Geo::ProjectRegistryMismatchFinder
        .new(current_node: current_node, type: type)
        .execute
    end
  end
end
