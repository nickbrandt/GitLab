# frozen_string_literal: true

module EE
  module API
    module Entities
      module Analytics
        module Reports
          class Series < Grape::Entity
            class Dataset < Grape::Entity
              expose :label
              expose :data
            end

            expose :labels
            expose :datasets, using: Dataset

            private

            def labels
              options[:data].keys
            end

            def datasets
              [
                {
                  label: object.title,
                  data: options[:data].values
                }
              ]
            end
          end
        end
      end
    end
  end
end
