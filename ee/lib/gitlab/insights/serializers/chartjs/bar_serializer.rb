# frozen_string_literal: true

module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class BarSerializer < Chartjs::BaseSerializer
          private

          # Ensure the input is of the form `Hash[Symbol|String, Integer]`.
          def validate!(input)
            valid = input.respond_to?(:values)
            valid &&= input.values.all? { |value| value.respond_to?(:to_i) }

            unless valid
              raise WrongInsightsFormatError, "Expected `input` to be of the form `Hash[Symbol|String, Integer]`, #{input} given!"
            end
          end

          # input - A hash of the form `Hash[Symbol|String, Integer]`, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 1,
          #     undefined: 2
          #   }
          #
          # Returns the series data as a hash, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 1,
          #     undefined: 2
          #   }
          def build_series_data(input)
            input
          end

          # series_data - A hash of the form `Hash[Symbol|String, Integer]`, e.g.
          #   {
          #     Manage: 1,
          #     Plan: 2
          #   }
          #
          # Returns a datasets array, e.g.
          #   [{ label: nil, data: [1, 2], borderColor: ['red', 'blue'] }]
          def chart_datasets(series_data)
            background_colors = series_data.keys.map { |name| generate_color_code(name) }

            [dataset(nil, series_data.values, background_colors)]
          end
        end
      end
    end
  end
end
