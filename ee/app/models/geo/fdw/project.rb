# frozen_string_literal: true

module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      include Gitlab::SQL::Pattern
      include Routable

      self.primary_key = :id
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('projects')

      has_many :job_artifacts, class_name: 'Geo::Fdw::Ci::JobArtifact'
      has_many :container_repositories, class_name: 'Geo::Fdw::ContainerRepository'

      belongs_to :namespace, class_name: 'Geo::Fdw::Namespace'
      belongs_to :design_management_designs, class_name: 'Geo::Fdw::DesignManagementDesign'

      scope :outside_shards, -> (shard_names) { where.not(repository_storage: Array(shard_names)) }

      alias_method :parent, :namespace

      delegate :disk_path, to: :storage

      def hashed_storage?(feature)
        raise ArgumentError, _("Invalid feature") unless ::Project::HASHED_STORAGE_FEATURES.include?(feature)

        self.storage_version && self.storage_version >= ::Project::HASHED_STORAGE_FEATURES[feature]
      end

      def repository
        @repository ||= Repository.new(full_path, self, shard: repository_storage, disk_path: disk_path)
      end

      def storage
        @storage ||=
          if hashed_storage?(:repository)
            Storage::Hashed.new(self)
          else
            Storage::LegacyProject.new(self)
          end
      end

      class << self
        def missing_project_registry
          left_outer_join_project_registry
            .where(Geo::ProjectRegistry.arel_table[:project_id].eq(nil))
        end

        def recently_updated
          inner_join_project_registry
            .merge(Geo::ProjectRegistry.dirty)
            .merge(Geo::ProjectRegistry.retry_due)
        end

        # Searches for a list of projects based on the query given in `query`.
        #
        # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
        # search.
        #
        # query - The search query as a String.
        def search(query)
          fuzzy_search(query, [:path, :name, :description])
        end

        def within_namespaces(namespace_ids)
          where(arel_table.name => { namespace_id: namespace_ids })
        end

        def within_shards(shard_names)
          where(repository_storage: Array(shard_names))
        end

        def inner_join_project_registry
          join_statement =
            arel_table
              .join(Geo::ProjectRegistry.arel_table, Arel::Nodes::InnerJoin)
              .on(arel_table[:id].eq(Geo::ProjectRegistry.arel_table[:project_id]))

          joins(join_statement.join_sources)
        end

        def inner_join_design_registry
          join_statement =
            arel_table
              .join(Geo::DesignRegistry.arel_table, Arel::Nodes::InnerJoin)
              .on(arel_table[:id].eq(Geo::DesignRegistry.arel_table[:project_id]))

          joins(join_statement.join_sources)
        end

        def missing_design_registry
          left_outer_join_design_registry
            .where(Geo::DesignRegistry.arel_table[:project_id].eq(nil))
        end

        def recently_updated_designs
          inner_join_design_registry
            .merge(Geo::DesignRegistry.updated_recently)
        end

        def with_designs
          design_table = Geo::Fdw::DesignManagementDesign.arel_table
          design_subquery = design_table.project(design_table[:project_id]).distinct.as('sub_design_table')

          join_statement =
            arel_table
              .join(design_subquery, Arel::Nodes::InnerJoin)
              .on(arel_table[:id].eq(design_subquery[:project_id]))

          joins(join_statement.join_sources)
        end

        private

        def left_outer_join_project_registry
          join_statement =
            arel_table
              .join(Geo::ProjectRegistry.arel_table, Arel::Nodes::OuterJoin)
              .on(arel_table[:id].eq(Geo::ProjectRegistry.arel_table[:project_id]))

          joins(join_statement.join_sources)
        end

        def left_outer_join_design_registry
          join_statement =
            arel_table
              .join(Geo::DesignRegistry.arel_table, Arel::Nodes::OuterJoin)
              .on(arel_table[:id].eq(Geo::DesignRegistry.arel_table[:project_id]))

          joins(join_statement.join_sources)
        end
      end
    end
  end
end
