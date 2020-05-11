# frozen_string_literal: true

# This model uses database table of another class and defines
# just a subset of the columns as attributes. The rationale
# behind is, encapsulating related logic in one place while
# being able to eager load the information.
#
# Later this model can use a different table which can be
# populated with the data by database triggers for performance
# reasons.
module Vulnerabilities
  class Stats < ApplicationRecord
    INHERITED_COLUMNS = %w(project_id).freeze

    self.table_name = 'vulnerabilities'
    self.primary_key = 'project_id'

    attribute :critical, :integer, default: 0
    attribute :high, :integer, default: 0
    attribute :medium, :integer, default: 0
    attribute :low, :integer, default: 0

    belongs_to :project

    default_scope { select(select_statement).group(:project_id) }

    after_initialize :readonly!

    class << self
      def select_statement
        @select_statement ||= INHERITED_COLUMNS + stats_select
      end

      # Overrides ActiveRecord::ModelSchema's method to do not inherit
      # all the attributes from vulnerabilities table.
      def ignored_columns
        Vulnerability.columns.map(&:name) - INHERITED_COLUMNS
      end

      private

      def stats_select
        Vulnerability.severities.map do |severity, enum|
          build_select_clause_for(severity, enum)
        end
      end

      def build_select_clause_for(severity, enum)
        "COUNT(*) FILTER (WHERE severity = #{enum}) as #{severity}"
      end
    end
  end
end
