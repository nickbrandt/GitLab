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
        def for_lfs_objects(ids)
          query
            .joins(fdw_inner_join_lfs_objects)
            .lfs_object_id_in(ids)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        private

        def base
          ::Geo::LfsObjectRegistry
            .select(registry_table[Arel.star])
        end

        def registry_table
          ::Geo::LfsObjectRegistry.arel_table
        end

        def fdw_table
          ::Geo::Fdw::LfsObject.arel_table
        end

        def fdw_inner_join_lfs_objects
          registry_table
              .join(fdw_table, Arel::Nodes::InnerJoin)
              .on(registry_table[:lfs_object_id].eq(fdw_table[:id]))
              .join_sources
        end
      end
    end
  end
end
