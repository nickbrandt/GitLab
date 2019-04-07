# frozen_string_literal: true

module Geo
  module Fdw
    class Upload < ::Geo::BaseFdw
      include Gitlab::SQL::Pattern
      include ObjectStorable

      STORE_COLUMN = :store

      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('uploads')

      scope :geo_syncable, -> { with_files_stored_locally }

      class << self
        # Searches for a list of uploads based on the query given in `query`.
        #
        # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
        # search.
        #
        # query - The search query as a String.
        def search(query)
          fuzzy_search(query, [:path])
        end
      end
    end
  end
end
