# frozen_string_literal: true

module Gitlab
  module Geo
    class Fdw
      DEFAULT_SCHEMA = 'public'
      FOREIGN_SERVER = 'gitlab_secondary'
      FOREIGN_SCHEMA = 'gitlab_secondary'

      class << self
        # Return if FDW is enabled for this instance
        #
        # @return [Boolean] whether FDW is enabled
        def enabled?
          return false unless fdw_capable?

          # FDW is enabled by default, disable it by setting `fdw: false` in config/database_geo.yml
          value = Rails.configuration.geo_database['fdw']
          value.nil? ? true : value
        end

        # Return full table name with foreign schema
        #
        # @param [String] table_name
        def foreign_table_name(table_name)
          FOREIGN_SCHEMA + ".#{table_name}"
        end

        def foreign_tables_up_to_date?
          has_foreign_schema? && foreign_schema_tables_match?
        end

        # Number of existing tables
        #
        # @return [Integer] number of tables
        def foreign_schema_tables_count
          Gitlab::Geo.cache_value(:geo_fdw_count_tables) do
            sql = <<~SQL
              SELECT COUNT(*)
                FROM information_schema.tables
               WHERE table_schema = '#{FOREIGN_SCHEMA}'
                 AND table_type = 'FOREIGN TABLE'
                 AND table_name NOT LIKE 'pg_%'
            SQL

            ::Geo::TrackingBase.connection.execute(sql).first.fetch('count').to_i
          end
        end

        def gitlab_schema_tables_count
          ActiveRecord::Schema.tables.reject { |table| table.start_with?('pg_') }.count
        end

        private

        def fdw_capable?
          has_foreign_server? && has_foreign_schema? && foreign_schema_tables_count.positive?
        end

        # Check if there is at least one foreign server configured
        #
        # @return [Boolean] whether any foreign server exists
        def has_foreign_server?
          ::Geo::TrackingBase.connection.execute(
            "SELECT 1 FROM pg_foreign_server"
          ).count.positive?
        end

        def has_foreign_schema?
          Gitlab::Geo.cache_value(:geo_FOREIGN_SCHEMA_exist) do
            sql = <<~SQL
              SELECT 1
                FROM information_schema.schemata
               WHERE schema_name='#{FOREIGN_SCHEMA}'
            SQL

            ::Geo::TrackingBase.connection.execute(sql).count.positive?
          end
        end

        # Check if foreign schema has exact the same tables and fields defined on secondary database
        #
        # @return [Boolean] whether schemas match and are not empty
        def foreign_schema_tables_match?
          Gitlab::Geo.cache_value(:geo_foreign_schema_tables_match) do
            gitlab_schema_tables = retrieve_gitlab_schema_tables.to_set
            foreign_schema_tables = retrieve_foreign_schema_tables.to_set

            gitlab_schema_tables.present? && (gitlab_schema_tables == foreign_schema_tables)
          end
        end

        def retrieve_foreign_schema_tables
          retrieve_schema_tables(::Geo::TrackingBase, Rails.configuration.geo_database['database'], FOREIGN_SCHEMA).to_a
        end

        def retrieve_gitlab_schema_tables
          retrieve_schema_tables(ActiveRecord::Base, ActiveRecord::Base.connection_config[:database], DEFAULT_SCHEMA).to_a
        end

        def retrieve_schema_tables(adapter, database, schema)
          sql = <<~SQL
              SELECT table_name, column_name, data_type
                FROM information_schema.columns
               WHERE table_catalog = '#{database}'
                 AND table_schema = '#{schema}'
                 AND table_name NOT LIKE 'pg_%'
            ORDER BY table_name, column_name, data_type
          SQL

          adapter.connection.select_all(sql)
        end
      end
    end
  end
end
