# frozen_string_literal: true

module Geo
  module Fdw
    class ProjectRegistry
      class << self
        def registries_pending_verification
          Geo::ProjectRegistry
            .joins(fdw_inner_join_projects)
            .joins(fdw_inner_join_repository_state)
            .where(repositories_pending_verification.or(wikis_pending_verification))
        end

        def within_namespaces(namespace_ids)
          Geo::ProjectRegistry
            .joins(fdw_inner_join_projects)
            .where(fdw_projects_table.name => { namespace_id: namespace_ids })
        end

        def within_shards(shard_names)
          Geo::ProjectRegistry
            .joins(fdw_inner_join_projects)
            .where(fdw_projects_table.name => { repository_storage: Array(shard_names) })
        end

        private

        def project_registries_table
          Geo::ProjectRegistry.arel_table
        end

        def fdw_projects_table
          Geo::Fdw::Project.arel_table
        end

        def fdw_repository_state_table
          Geo::Fdw::ProjectRepositoryState.arel_table
        end

        def fdw_inner_join_projects
          project_registries_table
            .join(fdw_projects_table, Arel::Nodes::InnerJoin)
            .on(project_registries_table[:project_id].eq(fdw_projects_table[:id]))
            .join_sources
        end

        def fdw_inner_join_repository_state
          project_registries_table
            .join(fdw_repository_state_table, Arel::Nodes::InnerJoin)
            .on(project_registries_table[:project_id].eq(fdw_repository_state_table[:project_id]))
            .join_sources
        end

        def repositories_pending_verification
          Geo::ProjectRegistry.repositories_pending_verification
            .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))
        end

        def wikis_pending_verification
          Geo::ProjectRegistry.wikis_pending_verification
            .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))
        end
      end
    end
  end
end
