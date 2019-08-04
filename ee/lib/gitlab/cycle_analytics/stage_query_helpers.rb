# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageQueryHelpers
      def execute_query(query)
        # Extract raw sql and variable bindings from arel query
        sql, binds = ActiveRecord::Base.connection.send(:to_sql_and_binds, query) # rubocop:disable GitlabSecurity/PublicSend

        ActiveRecord::Base.connection.exec_query(sql, nil, binds).to_a
      end

      def zero_interval
        Arel::Nodes::NamedFunction.new("CAST", [Arel.sql("'0' AS INTERVAL")])
      end

      def round_duration_to_seconds
        Arel::Nodes::Extract.new(duration, :epoch)
      end

      def duration
        Arel::Nodes::Subtraction.new(
          stage.end_event.timestamp_projection,
          stage.start_event.timestamp_projection
        )
      end
    end
  end
end
