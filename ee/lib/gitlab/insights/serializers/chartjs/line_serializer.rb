# frozen_string_literal: true

module Gitlab
  module Insights
    module Serializers
      module Chartjs
        class LineSerializer < Chartjs::MultiSeriesSerializer
          private

          # Returns a serie dataset, e.g.
          #   { label: 'Manage', data: [1, 2], borderColor: 'red' }
          def dataset(label, serie_data, color)
            {
              label: label,
              data: serie_data,
              borderColor: color
            }.with_indifferent_access
          end
        end
      end
    end
  end
end
