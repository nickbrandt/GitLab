# frozen_string_literal: true

require 'digest/md5'

module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class BaseSerializer
          BaseSerializerError = Class.new(StandardError)
          WrongInsightsFormatError = Class.new(BaseSerializerError)

          def self.present(input)
            new(input).present
          end

          def initialize(input)
            validate!(input)

            @labels = input.keys
            @insights = build_series_data(input)
          end
          private_class_method :new

          # Return a Chartjs-compatible hash, e.g.
          #   {
          #     labels: ['January', 'February'],
          #     datasets: [
          #       { label: 'Manage', data: [1, 2], backgroundColor: 'red' },
          #       { label: 'Plan', data: [2, 1], backgroundColor: 'blue' }
          #     ]
          #   }
          def present
            chart_data(labels, insights)
          end

          private

          attr_reader :labels, :insights

          # Can be overridden by subclasses.
          def validate!(input)
            # no-op
          end

          # Can be overridden by subclasses.
          def build_series_data(input)
            raise NotImplementedError
          end

          # labels - The series labels, e.g. [InsightLabel.new('January', '#990000'), InsightLabel.new('February', '#009900')].
          # series_data - The datasets hash, e.g.
          #   {
          #     InsightLabel.new('Manage', '#990000') => 1,
          #     InsightLabel.new('Plan', '#009900') => 2
          #   }
          # or
          #   {
          #     InsightLabel.new('Manage', '#990000') => [1, 2],
          #     InsightLabel.new('Plan', '#009900') => [2, 1]
          #   }
          #
          # Return a Chartjs-compatible hash, e.g.
          #   {
          #     labels: ['January', 'February'],
          #     datasets: [
          #       { label: 'Manage', data: [1, 2], backgroundColor: 'red' },
          #       { label: 'Plan', data: [2, 1], backgroundColor: 'blue' }
          #     ]
          #   }
          def chart_data(labels, series_data)
            {
              labels: labels.map(&:title),
              datasets: chart_datasets(series_data)
            }.with_indifferent_access
          end

          # Can be overridden by subclasses.
          #
          # series_data - The series hash, e.g.
          #   {
          #     InsightLabel.new('Manage', '#990000') => 1,
          #     InsightLabel.new('Plan', '#009900') => 2
          #   }
          # or
          #   {
          #     InsightLabel.new('Manage', '#990000') => [1, 2],
          #     InsightLabel.new('Plan', '#009900') => [2, 1]
          #   }
          #
          # Returns a ChartJS-compatible datasets array, e.g.
          #   [
          #     { label: 'Manage', data: [1, 2], backgroundColor: 'red' },
          #     { label: 'Plan', data: [2, 1], backgroundColor: 'blue' }
          #   ]
          def chart_datasets(series_data)
            series_data.map do |label, data|
              p label, data
              p label.color
              p label.color || generate_color_code_for_label(label.title)
              dataset(label.title, data, label.color || generate_color_code_for_label(label.title))
            end
          end

          # Can be overridden by subclasses.
          #
          # label_title - The serie's label.
          # data        - The serie's data array.
          # label_color - The serie's color.
          #
          # Returns a serie dataset, e.g.
          #   { label: 'Manage', data: [1, 2], backgroundColor: 'red' }
          def dataset(label_title, serie_data, label_color)
            {
              label: label_title,
              data: serie_data,
              backgroundColor: label_color
            }.with_indifferent_access
          end

          def generate_color_code_for_label(label)
            Gitlab::Insights::STATIC_COLOR_MAP[label] || "##{Digest::MD5.hexdigest(label.to_s)[0..5]}"
          end
        end
      end
    end
  end
end
