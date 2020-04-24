# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlAdapter
      module DumpSchemaVersionsMixin
        extend ActiveSupport::Concern

        def dump_schema_information # :nodoc:
          versions = schema_migration.all_versions
          touch_version_files(versions) if versions.any?

          nil
        end

        private

        def touch_version_files(versions)
          Gitlab::Database::SchemaVersionFiles.touch_all(versions)
        end
      end
    end
  end
end
