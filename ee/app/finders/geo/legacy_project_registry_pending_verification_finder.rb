# frozen_string_literal: true

# Finder for retrieving project registries that need a repository or
# wiki verification where projects belong to the specific shard
# using cross-database joins for selective sync.
#
# Basic usage:
#
#     Geo::LegacyProjectRegistryPendingVerificationFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute
module Geo
  class LegacyProjectRegistryPendingVerificationFinder < RegistryFinder
    def initialize(current_node: nil, shard_name:, batch_size:)
      super(current_node: current_node)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    def execute
      if use_legacy_queries?
        registries_pending_verification_for_selective_sync
      else
        registries_pending_verification
      end
    end

    private

    attr_reader :batch_size, :shard_name

    def local_registry_table
      Geo::ProjectRegistry.arel_table
    end

    def fdw_project_table
      Geo::Fdw::Project.arel_table
    end

    def fdw_repository_state_table
      Geo::Fdw::ProjectRepositoryState.arel_table
    end

    def fdw_inner_join_projects
      local_registry_table
        .join(fdw_project_table, Arel::Nodes::InnerJoin)
        .on(local_registry_table[:project_id].eq(fdw_project_table[:id]))
        .join_sources
    end

    def fdw_inner_join_repository_state
      local_registry_table
        .join(fdw_repository_state_table, Arel::Nodes::InnerJoin)
        .on(local_registry_table[:project_id].eq(fdw_repository_state_table[:project_id]))
        .join_sources
    end

    def local_repo_condition
      local_registry_table[:repository_verification_checksum_sha].eq(nil)
        .and(local_registry_table[:last_repository_verification_failure].eq(nil))
        .and(local_registry_table[:resync_repository].eq(false))
        .and(repository_missing_on_primary_is_not_true)
    end

    def repository_missing_on_primary_is_not_true
      Arel::Nodes::SqlLiteral.new("project_registry.repository_missing_on_primary IS NOT TRUE")
    end

    def local_wiki_condition
      local_registry_table[:wiki_verification_checksum_sha].eq(nil)
        .and(local_registry_table[:last_wiki_verification_failure].eq(nil))
        .and(local_registry_table[:resync_wiki].eq(false))
        .and(wiki_missing_on_primary_is_not_true)
    end

    def wiki_missing_on_primary_is_not_true
      Arel::Nodes::SqlLiteral.new("project_registry.wiki_missing_on_primary IS NOT TRUE")
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def registries_pending_verification
      repo_condition =
        local_repo_condition
          .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))

      wiki_condition =
        local_wiki_condition
          .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))

      Geo::ProjectRegistry
        .joins(fdw_inner_join_projects)
        .joins(fdw_inner_join_repository_state)
        .where(repo_condition.or(wiki_condition))
        .where(fdw_project_table[:repository_storage].eq(shard_name))
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def registries_pending_verification_for_selective_sync
      registries = Geo::ProjectRegistry
        .where(local_repo_condition.or(local_wiki_condition))
        .pluck(:project_id, local_repo_condition.to_sql, local_wiki_condition.to_sql)

      return Geo::ProjectRegistry.none if registries.empty?

      id_and_want_to_sync = registries.map do |project_id, want_to_sync_repo, want_to_sync_wiki|
        "(#{project_id}, #{quote_value(want_to_sync_repo)}, #{quote_value(want_to_sync_wiki)})"
      end

      project_registry_sync_table = Arel::Table.new(:project_registry_sync_table)

      joined_relation =
        ProjectRepositoryState.joins(<<~SQL_REPO)
          INNER JOIN
          (VALUES #{id_and_want_to_sync.join(',')})
          project_registry_sync_table(project_id, want_to_sync_repo, want_to_sync_wiki)
          ON #{legacy_repository_state_table.name}.project_id = project_registry_sync_table.project_id
        SQL_REPO

      project_ids = joined_relation
        .joins(:project)
        .where(projects: { repository_storage: shard_name })
        .where(
          legacy_repository_state_table[:repository_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_repo].eq(true))
          .or(legacy_repository_state_table[:wiki_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_wiki].eq(true))))
        .limit(batch_size)
        .pluck(:project_id)

      legacy_inner_join_registry_ids(
        Geo::ProjectRegistry.where(project_id: project_ids),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def legacy_repository_state_table
      ::ProjectRepositoryState.arel_table
    end
  end
end
