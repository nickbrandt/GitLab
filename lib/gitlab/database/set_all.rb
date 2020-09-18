# frozen_string_literal: true

module Gitlab
  module Database
    # Constructs queries of the form:
    #
    #   with cte(a, b, c) as (
    #     select * from (values (:x, :y, :z), (:q, :r, :s)) as t
    #     )
    #   update table set b = cte.b, c = cte.c where a = cte.a
    #
    # Which is useful if you want to update a set of records in a single query
    # but cannot express the update as a calculation (i.e. you have arbitrary
    # updates to perform).
    #
    # The requirements are that the table must have an ID column used to
    # identify the rows to be updated.
    module SetAll
      COMMA = ', '

      class Setter
        include Gitlab::Utils::StrongMemoize

        attr_reader :table_name, :connection, :columns, :mapping

        def initialize(model, columns, mapping)
          raise ArgumentError if columns.blank? || columns.any? { |c| !c.is_a?(Symbol) }
          raise ArgumentError if mapping.nil? || mapping.empty?
          raise ArgumentError if mapping.any? { |_k, v| !v.is_a?(Hash) }

          @table_name = model.table_name
          @connection = model.connection
          @columns = ([:id] + columns).map { |c| [c, model.column_for_attribute(c)] }
          @mapping = mapping
        end

        def params
          mapping.flat_map do |k, v|
            obj_id = k.try(:id) || k
            v = v.merge(id: obj_id)
            columns.map { |c| query_attribute(c, k, v) }
          end
        end

        # A workaround for https://github.com/rails/rails/issues/24893
        # We need to detect if prepared statements have been disabled.
        def no_prepared_statement?
          strong_memoize(:no_prepared_statement) do
            connection.send(:without_prepared_statement?, [1]) # rubocop: disable GitlabSecurity/PublicSend
          end
        end

        def query_attribute(column, key, values)
          column_name = column.first
          value = values[column_name]
          key[column_name] = value if key.try(:id) # optimistic update
          ActiveRecord::Relation::QueryAttribute.from_user(nil, value, ActiveModel::Type.lookup(column.second.type))
        end

        def values
          counter = 0
          typed = false

          mapping.map do |k, v|
            binds = columns.map do |c|
              bind = "$#{counter += 1}"
              # PG is not great at inferring types - help it for the first row.
              bind += "::#{c.second.sql_type}" unless typed
              bind
            end
            typed = true

            "(#{binds.join(COMMA)})"
          end
        end

        def sql
          column_names = columns.map(&:first)
          cte_columns = column_names.map do |c|
            connection.quote_column_name("cte_#{c}")
          end
          updates = column_names.zip(cte_columns).drop(1).map do |dest, src|
            "#{connection.quote_column_name(dest)} = cte.#{src}"
          end

          <<~SQL
            WITH cte(#{cte_columns.join(COMMA)}) AS (VALUES #{values.join(COMMA)})
            UPDATE #{table_name} SET #{updates.join(COMMA)} FROM cte WHERE cte_id = id
          SQL
        end

        def update!
          log_name = "SetAll #{table_name} #{columns.drop(1).map(&:first)}:#{mapping.size}"
          if no_prepared_statement?
            # A workaround for https://github.com/rails/rails/issues/24893
            # When prepared statements are prevented (such as when using the
            # query counter or in omnibus by default), we cannot call
            # `exec_update`, since that will discard the bindings.
            connection.send(:exec_no_cache, sql, log_name, params) # rubocop: disable GitlabSecurity/PublicSend
          else
            connection.exec_update(sql, log_name, params)
          end
        end
      end

      def self.set_all(columns, mapping)
        mapping.group_by { |k, v| k.class }.each do |model, entries|
          Setter.new(model, columns, entries).update!
        end
      end
    end
  end
end
