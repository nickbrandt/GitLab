# frozen_string_literal: true

# Builder class to create composable queries using FDW to
# retrieve file registries.
#
# Basic usage:
#
#     Gitlab::Geo::Fdw::FileRegistryQueryBuilder
#       .new
#       .for_project_with_type(project, 'file')
#
module Gitlab
  module Geo
    class Fdw
      class FileRegistryQueryBuilder < BaseQueryBuilder
        # rubocop:disable CodeReuse/ActiveRecord
        def for_model(model)
          reflect(
            query
              .joins(fdw_inner_join_uploads)
              .where(
                fdw_upload_table[:model_id].eq(model.id)
                  .and(fdw_upload_table[:model_type].eq(model.class.name))
              )
          )
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def with_type(type)
          reflect(query.merge(::Geo::FileRegistry.with_file_type(type)))
        end

        private

        def base
          ::Geo::FileRegistry.select(file_registry_table[Arel.star])
        end

        def file_registry_table
          ::Geo::FileRegistry.arel_table
        end

        def fdw_upload_table
          ::Geo::Fdw::Upload.arel_table
        end

        def fdw_inner_join_uploads
          file_registry_table
            .join(fdw_upload_table, Arel::Nodes::InnerJoin)
            .on(file_registry_table[:file_id].eq(fdw_upload_table[:id]))
            .join_sources
        end
      end
    end
  end
end
