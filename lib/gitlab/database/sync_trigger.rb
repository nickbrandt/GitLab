# frozen_string_literal: true

module Gitlab
  module Database
    class SyncTrigger
      include ::Gitlab::Database::SchemaHelpers

      DELIMITER = ",\n    "

      def self.for_table(source_table_name, message_context:, logger: Gitlab::AppLogger)
        new(source_table_name, message_context, logger)
      end

      attr_reader :source_table_name

      def create(destination_table_name, key_column_name)
        create_sync_function(destination_table_name, key_column_name)
        create_comment('FUNCTION', function_name, "#{message_context}: table sync for #{source_table_name} table")

        create_sync_trigger
      end

      def drop
        drop_sync_trigger
        drop_sync_function
      end

      def trigger_name
        @trigger_name ||= object_name(source_table_name, 'table_sync_trigger')
      end

      def function_name
        @function_name ||= object_name(source_table_name, 'table_sync_function')
      end

      private

      attr_reader :message_context, :logger

      def initialize(source_table_name, message_context, logger)
        @source_table_name = source_table_name
        @message_context = message_context
        @logger = logger
      end

      def create_sync_function(destination_table_name, key_column_name)
        if function_exists?(function_name)
          logger.warn "#{message_context} sync function not created because it already exists: #{function_name}"
          return
        end

        destination_table_name = connection.quote_table_name(destination_table_name)
        key_column_name = connection.quote_column_name(key_column_name)

        set_statements = build_set_statements(key_column_name)
        insert_values = quoted_column_names.map { |name| "NEW.#{name}" }

        create_trigger_function(function_name, replace: false) do
          <<~SQL
            IF (TG_OP = 'DELETE') THEN
              DELETE FROM #{destination_table_name} where #{key_column_name} = OLD.#{key_column_name};
            ELSIF (TG_OP = 'UPDATE') THEN
              UPDATE #{destination_table_name}
              SET #{set_statements.join(DELIMITER)}
              WHERE #{destination_table_name}.#{key_column_name} = NEW.#{key_column_name};
            ELSIF (TG_OP = 'INSERT') THEN
              INSERT INTO #{destination_table_name} (#{quoted_column_names.join(DELIMITER)})
              VALUES (#{insert_values.join(DELIMITER)});
            END IF;
            RETURN NULL;
          SQL
        end
      end

      def create_sync_trigger
        if trigger_exists?(source_table_name, trigger_name)
          logger.warn "#{message_context} sync trigger not created because it already exists: #{trigger_name}"
          return
        end

        create_trigger(source_table_name, trigger_name, function_name, fires: 'AFTER INSERT OR UPDATE OR DELETE')
      end

      def drop_sync_trigger
        unless trigger_exists?(source_table_name, trigger_name)
          logger.warn "#{message_context} sync trigger not dropped because it doesn't exist: #{trigger_name}"
          return
        end

        drop_trigger(source_table_name, trigger_name)
      end

      def drop_sync_function
        unless function_exists?(function_name)
          logger.warn "#{message_context} sync function not dropped because it doesn't exist: #{function_name}"
          return
        end

        drop_function(function_name)
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def quoted_column_names
        @quoted_column_names ||= connection.columns(source_table_name)
          .map { |column| connection.quote_column_name(column.name) }
      end

      def build_set_statements(unique_key)
        quoted_column_names.reject { |name| name == unique_key }.map { |name| "#{name} = NEW.#{name}" }
      end
    end
  end
end
