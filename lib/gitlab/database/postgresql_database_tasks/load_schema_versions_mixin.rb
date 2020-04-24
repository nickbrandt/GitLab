# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlDatabaseTasks
      module LoadSchemaVersionsMixin
        extend ActiveSupport::Concern

        def structure_load(*args)
          super(*args)
          load_version_files
        end

        private

        def load_version_files
          Gitlab::Database::SchemaVersionFiles.load_all
        end
      end
    end
  end
end
