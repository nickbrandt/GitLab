# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class Median
      include StageQueryHelpers

      attr_reader :stage, :query

      def initialize(stage, query)
        @stage = stage
        @query = query
      end

      def seconds
        result = execute_query(query.project(median_duration_in_seconds.as('median'))).first || {}
        result['median'] ? result['median'].to_i : nil
      end

      private

      def percentile_cont
        percentile_disc_ordering = Arel::Nodes::UnaryOperation.new(Arel::Nodes::SqlLiteral.new('ORDER BY'), duration)
        Arel::Nodes::NamedFunction.new(
          'percentile_cont(0.5) WITHIN GROUP',
          [percentile_disc_ordering]
        )
      end

      def median_duration_in_seconds
        Arel::Nodes::Extract.new(percentile_cont, :epoch)
      end
    end
  end
end
