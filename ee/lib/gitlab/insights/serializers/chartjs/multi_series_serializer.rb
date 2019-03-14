# frozen_string_literal: true

module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class MultiSeriesSerializer < Chartjs::BaseSerializer
          private

          # Ensure the input is of the form `Hash[Symbol|String, Hash[Symbol|String, Integer]]`.
          def validate!(input)
            valid = input.respond_to?(:values)
            valid &&= input.values.all? do |value|
              value.respond_to?(:values) &&
                value.values.respond_to?(:all?) &&
                value.all? { |_key, count| count.respond_to?(:to_i) }
            end

            unless valid
              raise WrongInsightsFormatError, "Expected `input` to be of the form `Hash[Symbol|String, Hash[Symbol|String, Integer]]`, #{input} given!"
            end
          end

          # input - A hash of the form `Hash[Symbol|String, Hash[Symbol|String, Integer]]`, e.g.
          #   {
          #     'January 2019' => {
          #       Manage: 1,
          #       Plan: 1,
          #       undefined: 2
          #     },
          #     'February 2019' => {
          #       Manage: 0,
          #       Plan: 1,
          #       undefined: 0
          #     }
          #   }
          #
          # Returns the series data as a hash, e.g.
          #   {
          #     Manage: [1, 0],
          #     Plan: [1, 1],
          #     undefined: [2, 0]
          #   }
          def build_series_data(input)
            input.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(_, data), series_data|
              data.each do |serie_name, count|
                series_data[serie_name] << count
              end
            end
          end
        end
      end
    end
  end
end
