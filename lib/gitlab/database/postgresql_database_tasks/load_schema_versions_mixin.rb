# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlDatabaseTasks
      module LoadSchemaVersionsMixin
        extend ActiveSupport::Concern

        def structure_load(...)
          super(...)

          Gitlab::Database::SchemaVersionFiles.load_all(connection.pool.db_config.name)
        end
      end
    end
  end
end
