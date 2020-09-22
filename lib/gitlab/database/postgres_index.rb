# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresIndex < ActiveRecord::Base
      self.table_name = 'postgres_indexes'
      self.primary_key = 'identifier'

      scope :by_identifier, ->(identifier) do
        raise ArgumentError, "Index name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        find(identifier)
      end

      scope :non_unique, -> { where(unique: false) }
      scope :non_partitioned, -> { where(partitioned: false) }

      scope :random_few, ->(how_many) do
        limit(how_many).order(Arel.sql('RANDOM()'))
      end

      def to_s
        name
      end
    end
  end
end
