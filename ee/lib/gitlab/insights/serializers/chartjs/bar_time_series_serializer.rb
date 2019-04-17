# frozen_string_literal: true

module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class BarTimeSeriesSerializer < Chartjs::BarSerializer
          private

          # series_data - A hash of the form `Hash[Symbol|String, Integer]`, e.g.
          #   {
          #     "January 2019": 1,
          #     "February 2019": 2
          #   }
          #
          # Returns a datasets array, e.g.
          #   [{ label: nil, data: [1, 2], borderColor: ['#428bca', '#ffd8b1'] }]
          def chart_datasets(series_data)
            background_colors = Array.new(series_data.size - 1, Gitlab::Insights::DEFAULT_COLOR)
            background_colors << Gitlab::Insights::COLOR_SCHEME[:apricot]

            [dataset(nil, series_data.values, background_colors)]
          end
        end
      end
    end
  end
end
