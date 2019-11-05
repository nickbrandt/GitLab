# frozen_string_literal: true

# Builder class to create composable queries using FDW to
# retrieve file registries for LFS objects.
#
# Basic usage:
#
#     Gitlab::Geo::Fdw::LfsObjectRegistryQueryBuilder
#       .new
#       .inner_join_lfs_objects
#
module Gitlab
  module Geo
    class Fdw
      class LfsObjectRegistryQueryBuilder < BaseQueryBuilder
        # rubocop:disable CodeReuse/ActiveRecord
        def for_lfs_objects(lfs_object_ids)
          query
            .joins(fdw_inner_join_lfs_objects)
            .lfs_object_id_in(lfs_object_ids)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        private

        def base
          ::Geo::LfsObjectRegistry
            .select(lfs_registry_table[Arel.star])
        end

        def lfs_registry_table
          ::Geo::LfsObjectRegistry.arel_table
        end

        def fdw_lfs_object_table
          ::Geo::Fdw::LfsObject.arel_table
        end

        def fdw_inner_join_lfs_objects
          lfs_registry_table
              .join(fdw_lfs_object_table, Arel::Nodes::InnerJoin)
              .on(lfs_registry_table[:lfs_object_id].eq(fdw_lfs_object_table[:id]))
              .join_sources
        end
      end
    end
  end
end
