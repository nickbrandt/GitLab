# frozen_string_literal: true

# Builder class to create composable queries using FDW to
# retrieve project registries.
#
# Basic usage:
#
#     Gitlab::Geo::Fdw::ProjectRegistryQueryBuilder
#       .new(Geo::ProjectRegistry.all)
#       .registries_pending_verification
#       .within_shards(selective_sync_shards)
#
module Gitlab
  module Geo
    class Fdw
      class ProjectRegistryQueryBuilder < BaseQueryBuilder
        # rubocop:disable CodeReuse/ActiveRecord
        def registries_pending_verification
          reflect(
            query
              .joins(fdw_inner_join_projects)
              .joins(fdw_inner_join_repository_state)
              .where(repositories_pending_verification.or(wikis_pending_verification))
          )
        end
        # rubocop:enable CodeReuse/ActiveRecord

        # rubocop:disable CodeReuse/ActiveRecord
        def within_namespaces(namespace_ids)
          reflect(
            query
              .joins(fdw_inner_join_projects)
              .merge(projects_within_namespaces(namespace_ids))
          )
        end
        # rubocop:enable CodeReuse/ActiveRecord

        # rubocop:disable CodeReuse/ActiveRecord
        def within_shards(shard_names)
          reflect(
            query
              .joins(fdw_inner_join_projects)
              .merge(projects_within_shards(shard_names))
          )
        end
        # rubocop:enable CodeReuse/ActiveRecord

        private

        def base
          ::Geo::ProjectRegistry.select(project_registries_table[Arel.star])
        end

        def project_registries_table
          ::Geo::ProjectRegistry.arel_table
        end

        def fdw_projects_table
          ::Geo::Fdw::Project.arel_table
        end

        def fdw_repository_state_table
          ::Geo::Fdw::ProjectRepositoryState.arel_table
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

        def projects_within_namespaces(namespace_ids)
          ::Geo::Fdw::Project.within_namespaces(namespace_ids)
        end

        def projects_within_shards(shard_names)
          ::Geo::Fdw::Project.within_shards(shard_names)
        end

        def repositories_pending_verification
          ::Geo::ProjectRegistry
            .repositories_pending_verification
            .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))
        end

        def wikis_pending_verification
          ::Geo::ProjectRegistry
            .wikis_pending_verification
            .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))
        end
      end
    end
  end
end
