# frozen_string_literal: true

module EE
  module Types
    module MilestoneType
      extend ActiveSupport::Concern

      prepended do
        field :burnup_time_series, [::Types::BurnupChartDailyTotalsType], null: true,
              resolver: ::Resolvers::MilestoneBurnupTimeSeriesResolver,
              description: 'Daily scope and completed totals for burnup charts',
              complexity: 175
      end
    end
  end
end
