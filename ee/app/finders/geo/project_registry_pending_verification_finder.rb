# frozen_string_literal: true

# Finder for retrieving project registries that that need a repository or
# wiki verification where projects belong to the specific shard using
# FDW queries.
#
# Basic usage:
#
#     Geo::ProjectRegistryPendingVerificationFinder
#       .new(current_node: Gitlab::Geo.current_node, shard_name: 'default', batch_size: 1000)
#       .execute.
module Geo
  class ProjectRegistryPendingVerificationFinder
    def initialize(current_node:, shard_name:, batch_size:)
      @current_node = Geo::Fdw::GeoNode.find(current_node.id)
      @shard_name = shard_name
      @batch_size = batch_size
    end

    def execute
      repo_condition =
        local_repo_condition
          .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))

      wiki_condition =
        local_wiki_condition
          .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))

      current_node.project_registries
        .joins(fdw_inner_join_projects)
        .joins(fdw_inner_join_repository_state)
        .where(repo_condition.or(wiki_condition))
        .where(fdw_project_table[:repository_storage].eq(shard_name))
        .limit(batch_size)
    end

    private

    attr_reader :current_node, :shard_name,:batch_size

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
  end
end

