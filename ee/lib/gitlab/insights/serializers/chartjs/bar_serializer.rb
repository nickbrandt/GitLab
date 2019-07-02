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
          #     #<InsightLabel @title='Manage', @color='#990000'> => 1,
          #     #<InsightLabel @title='Plan', @color='#009900'> => 1,
          #     #<InsightLabel @title='undefined', @color='#000099'> => 2
          #   }
          #
          # Returns the `input` as-is.
          def build_series_data(input)
            input
          end

          # series_data - A hash of the form `Hash[Symbol|String, Integer]`, e.g.
          #   {
          #     #<InsightLabel @title='Manage', @color='#990000'> => 1,
          #     #<InsightLabel @title='Plan', @color='#009900'> => 1,
          #     #<InsightLabel @title='undefined', @color='#000099'> => 2
          #   }
          #
          # Returns a datasets array, e.g.
          #   [{ label: nil, data: [1, 2, 1], borderColor: ['#990000', '#009900', '#000099'] }]
          def chart_datasets(series_data)
            background_colors = series_data.keys.map { |label| label.color || generate_color_code_for_label(label.title) }

            [dataset(nil, series_data.values, background_colors)]
          end
        end
      end
    end
  end
end
