# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DurationChartDataFetcher
      include Gitlab::Database::DateTime
      include Gitlab::Database::Median

      def initialize(stage)
        @stage = stage
      end

      def fetch
        ActiveRecord::Base.connection.execute(build_query.to_sql).to_a.map do |row|
          [DateTime.strptime(row['finished_at'].to_s, '%s'), row['duration_in_seconds'].round(2)]
        end
      end

      private

      attr_reader :stage

      def build_query
        query = stage.stage_query(stage.projects.map(&:id))

        query.projections = [] # clear existing projections
        query.project(seconds_took.as('duration_in_seconds'))
        query.project(finished_at.as('finished_at'))
        query.where(duration.gteq(zero_interval))
        query
      end

      def seconds_took
        epoch(duration)
      end

      def duration
        subtract_datetimes_diff(nil, stage.start_time_attrs, stage.end_time_attrs)
      end

      def epoch(date)
        Arel::Nodes::NamedFunction.new("EXTRACT", [Arel::Nodes::NamedFunction.new("EPOCH FROM", [date])])
      end

      def finished_at
        epoch(Arel::Nodes::NamedFunction.new("COALESCE", Array.wrap(stage.end_time_attrs)))
      end
    end
  end
end
