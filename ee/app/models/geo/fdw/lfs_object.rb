# frozen_string_literal: true

module Geo
  module Fdw
    class LfsObject < ::Geo::BaseFdw
      include ObjectStorable

      STORE_COLUMN = :file_store

      self.primary_key = :id
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('lfs_objects')

      has_many :lfs_objects_projects, class_name: 'Geo::Fdw::LfsObjectsProject'
      has_many :projects, class_name: 'Geo::Fdw::Project', through: :lfs_objects_projects

      scope :project_id_in, ->(ids) { joins(:projects).merge(Geo::Fdw::Project.id_in(ids)) }

      class << self
        def failed
          inner_join_registry
            .merge(Geo::LfsObjectRegistry.failed)
        end

        def inner_join_registry
          join_statement =
            arel_table
              .join(registry_table, Arel::Nodes::InnerJoin)
              .on(arel_table[:id].eq(registry_table[:lfs_object_id]))

          joins(join_statement.join_sources)
        end

        def missing_registry
          left_outer_join_registry
            .where(registry_table[:id].eq(nil))
        end

        def missing_on_primary
          inner_join_registry
            .merge(Geo::LfsObjectRegistry.synced.missing_on_primary)
        end

        def synced
          inner_join_registry
            .merge(Geo::LfsObjectRegistry.synced)
        end

        private

        def registry_table
          Geo::LfsObjectRegistry.arel_table
        end

        def left_outer_join_registry
          join_statement =
            arel_table
              .join(registry_table, Arel::Nodes::OuterJoin)
              .on(arel_table[:id].eq(registry_table[:lfs_object_id]))

          joins(join_statement.join_sources)
        end
      end
    end
  end
end
