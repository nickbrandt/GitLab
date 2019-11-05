# frozen_string_literal: true

# Builder class to create composable queries using FDW to
# retrieve file registries.
#
# Basic usage:
#
#     Gitlab::Geo::Fdw::UploadRegistryQueryBuilder.new.for_model(project)
#
module Gitlab
  module Geo
    class Fdw
      class UploadRegistryQueryBuilder < BaseQueryBuilder
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

        private

        def base
          ::Geo::UploadRegistry.select(file_registry_table[Arel.star])
        end

        def file_registry_table
          ::Geo::UploadRegistry.arel_table
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
