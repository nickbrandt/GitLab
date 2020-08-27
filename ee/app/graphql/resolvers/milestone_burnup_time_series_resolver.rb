# frozen_string_literal: true

module Resolvers
  class MilestoneBurnupTimeSeriesResolver < BaseResolver
    type [Types::BurnupChartDailyTotalsType], null: true

    alias_method :milestone, :synchronized_object

    def resolve(*args)
      return [] unless milestone.burnup_charts_available?

      response = Milestones::BurnupChartService.new(milestone).execute

      raise GraphQL::ExecutionError, response.message if response.error?

      response.payload
    end
  end
end
