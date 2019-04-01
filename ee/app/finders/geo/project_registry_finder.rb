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

    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced_projects(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_projects
        else
          fdw_find_unsynced_projects
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_projects_updated_recently(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_projects_updated_recently
        else
          fdw_find_projects_updated_recently
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    protected

    #
    # FDW accessors
    #

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_unsynced_projects
      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON project_registry.project_id = #{fdw_project_table.name}.id")
        .where(project_registry: { project_id: nil })
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_projects_updated_recently
      Geo::Fdw::Project.joins("INNER JOIN project_registry ON project_registry.project_id = #{fdw_project_table.name}.id")
          .merge(Geo::ProjectRegistry.dirty)
          .merge(Geo::ProjectRegistry.retry_due)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    #
    # Legacy accessors (non FDW)
    #

    # @return [ActiveRecord::Relation<Project>] list of unsynced projects
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_unsynced_projects
      legacy_left_outer_join_registry_ids(
        current_node.projects,
        Geo::ProjectRegistry.pluck(:project_id),
        Project
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Project>] list of projects updated recently
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_projects_updated_recently
      registries = Geo::ProjectRegistry.dirty.retry_due.pluck(:project_id, :last_repository_synced_at)
      return Project.none if registries.empty?

      id_and_last_sync_values = registries.map do |id, last_repository_synced_at|
        "(#{id}, #{quote_value(last_repository_synced_at)})"
      end

      joined_relation = current_node.projects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{id_and_last_sync_values.join(',')})
        project_registry(id, last_repository_synced_at)
        ON #{Project.table_name}.id = project_registry.id
      SQL

      joined_relation
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def fdw_project_table
      Geo::Fdw::Project.arel_table
    end

    private

    def use_legacy_queries_for_selective_sync?
      selective_sync? && !Gitlab::Geo::Fdw.enabled_for_selective_sync?
    end

    def finder_klass_for_synced_registries
      if Gitlab::Geo::Fdw.enabled_for_selective_sync?
        Geo::ProjectRegistrySyncedFinder
      else
        Geo::LegacyProjectRegistrySyncedFinder
      end
    end

    def registries_for_synced_projects(type)
      finder_klass_for_synced_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_failed_registries
      if Gitlab::Geo::Fdw.enabled_for_selective_sync?
        Geo::ProjectRegistrySyncFailedFinder
      else
        Geo::LegacyProjectRegistrySyncFailedFinder
      end
    end

    def registries_for_failed_projects(type)
      finder_klass_for_failed_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_verified_registries
      if !Gitlab::Geo::Fdw.enabled? || use_legacy_queries_for_selective_sync?
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
      if Gitlab::Geo::Fdw.enabled_for_selective_sync?
        Geo::ProjectRegistryVerificationFailedFinder
      else
        Geo::LegacyProjectRegistryVerificationFailedFinder
      end
    end

    def registries_for_verification_failed_projects(type)
      finder_klass_for_verification_failed_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_registries_retrying_verification
      if Gitlab::Geo::Fdw.enabled_for_selective_sync?
        Geo::ProjectRegistryRetryingVerificationFinder
      else
        Geo::LegacyProjectRegistryRetryingVerificationFinder
      end
    end

    def registries_retrying_verification(type)
      finder_klass_for_registries_retrying_verification
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_mismatch_registries
      if Gitlab::Geo::Fdw.enabled_for_selective_sync?
        Geo::ProjectRegistryMismatchFinder
      else
        Geo::LegacyProjectRegistryMismatchFinder
      end
    end

    def registries_for_mismatch_projects(type)
      finder_klass_for_mismatch_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def finder_klass_for_registries_pending_verification
      if !Gitlab::Geo::Fdw.enabled? || use_legacy_queries_for_selective_sync?
        Geo::LegacyProjectRegistryPendingVerificationFinder
      else
        Geo::ProjectRegistryPendingVerificationFinder
      end
    end
  end
end
