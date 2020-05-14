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
    STATIC_SELECT_ATTRS = ['project_id', 'COUNT(*) AS count_all'].freeze

    self.table_name = 'vulnerabilities'
    self.primary_key = 'project_id'

    attribute :count_all, :integer, default: 0
    attribute :critical, :integer, default: 0
    attribute :high, :integer, default: 0
    attribute :medium, :integer, default: 0
    attribute :low, :integer, default: 0
    attribute :unknown, :integer, default: 0
    attribute :info, :integer, default: 0

    belongs_to :project

    scope :with_stats_schema, -> { select(stats_select_statement).group(:project_id) }

    after_initialize :readonly!

    class << self
      def stats_select_statement
        @stats_select_statement ||= STATIC_SELECT_ATTRS + stats_select
      end

      # Overrides ActiveRecord::ModelSchema's method to do not inherit
      # all the attributes from vulnerabilities table.
      def ignored_columns
        Vulnerability.columns.map(&:name) - [primary_key]
      end

      private

      def stats_select
        Vulnerability.severities.map do |severity, enum|
          build_select_clause_for(severity, enum)
        end
      end

      def build_select_clause_for(severity, enum)
        "COUNT(*) FILTER (WHERE severity = #{enum} AND state IN (#{active_states})) as #{severity}"
      end

      def active_states
        @active_states ||= Vulnerability.active_state_enums.join(',')
      end
    end
  end
end
