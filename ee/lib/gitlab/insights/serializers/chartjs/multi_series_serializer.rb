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
          #       InsightLabel.new('Manage', '#990000') => 1,
          #       InsightLabel.new('Plan', '#009900') => 1,
          #       InsightLabel.new('undefined', '#000099') => 2
          #     },
          #     'February 2019' => {
          #       InsightLabel.new('Manage', '#990000') => 0,
          #       InsightLabel.new('Plan', '#009900') => 1,
          #       InsightLabel.new('undefined', '#000099') => 1
          #     }
          #   }
          #
          # Returns the series data as a hash, e.g.
          #   {
          #     InsightLabel.new('Manage', '#990000') => [1, 0],
          #     InsightLabel.new('Plan', '#009900') => [1, 1],
          #     InsightLabel.new('undefined', '#000099') => [2, 1]
          #   }
          def build_series_data(input)
            initial_hash = Hash.new { |h, k| h[k] = [] }
            input.each_with_object(initial_hash) do |(_, data), series_data|
              data.each do |insight_label, count|
                # Use the first InsightLabel that equals the current one to populate the hash key
                insight_label_key, _ = series_data.detect { |k, _| k == insight_label }
                series_data[insight_label_key || insight_label] << count
              end
            end
          end
        end
      end
    end
  end
end
