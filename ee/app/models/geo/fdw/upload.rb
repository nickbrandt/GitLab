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
        def for_model_with_type(model, type)
          inner_join_file_registry
            .where(model_id: model.id, model_type: model.class.name)
            .merge(Geo::FileRegistry.with_file_type(type))
        end

        # Searches for a list of uploads based on the query given in `query`.
        #
        # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
        # search.
        #
        # query - The search query as a String.
        def search(query)
          fuzzy_search(query, [:path])
        end

        private

        def inner_join_file_registry
          join_statement =
            arel_table
              .join(file_registry_table, Arel::Nodes::InnerJoin)
              .on(arel_table[:id].eq(file_registry_table[:file_id]))

          joins(join_statement.join_sources)
        end

        def file_registry_table
          Geo::FileRegistry.arel_table
        end
      end
    end
  end
end
