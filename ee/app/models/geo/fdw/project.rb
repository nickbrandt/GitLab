# frozen_string_literal: true

module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      include Gitlab::SQL::Pattern
      include Routable

      self.primary_key = :id
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('projects')

      has_many :container_repositories, class_name: 'Geo::Fdw::ContainerRepository'

      belongs_to :namespace, class_name: 'Geo::Fdw::Namespace'

      alias_method :parent, :namespace

      class << self
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
      end
    end
  end
end
