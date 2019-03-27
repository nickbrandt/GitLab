# frozen_string_literal: true

module Geo
  module Fdw
    class Project < ::Geo::BaseFdw
      include Gitlab::SQL::Pattern

      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('projects')

      scope :within_shard, -> (shard_name) { arel_table[:repository_storage].eq(shard_name) }

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
      end
    end
  end
end
