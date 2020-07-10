# frozen_string_literal: true

module EE
  module API
    module Entities
      module Analytics
        module Reports
          class Chart < Grape::Entity
            class ChartSeriesConfig < Grape::Entity
              expose :id
              expose :title
            end

            class ChartConfig < Grape::Entity
              expose :type
              expose :series, using: ChartSeriesConfig
            end

            expose :id
            expose :title
            expose :chart, using: ChartConfig
          end
        end
      end
    end
  end
end
