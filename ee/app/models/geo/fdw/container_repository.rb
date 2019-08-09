# frozen_string_literal: true

module Geo
  module Fdw
    class ContainerRepository < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('container_repositories')
      self.primary_key = :id

      belongs_to :project, class_name: 'Geo::Fdw::Project', inverse_of: :container_repositories

      scope :project_id_in, ->(ids) { joins(:project).merge(Geo::Fdw::Project.id_in(ids)) }

      class << self
        def inner_join_container_repository_registry
          join_statement =
            arel_table
              .join(container_repository_registry_table, Arel::Nodes::InnerJoin)
              .on(arel_table[:id].eq(container_repository_registry_table[:container_repository_id]))

          joins(join_statement.join_sources)
        end

        def missing_container_repository_registry
          left_outer_join_container_repository_registry
            .where(container_repository_registry_table[:id].eq(nil))
        end

        private

        def container_repository_registry_table
          Geo::ContainerRepositoryRegistry.arel_table
        end

        def left_outer_join_container_repository_registry
          join_statement =
            arel_table
              .join(container_repository_registry_table, Arel::Nodes::OuterJoin)
              .on(arel_table[:id].eq(container_repository_registry_table[:container_repository_id]))

          joins(join_statement.join_sources)
        end
      end
    end
  end
end
