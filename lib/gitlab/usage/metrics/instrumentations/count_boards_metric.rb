# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountBoardsMetric < BaseMetric
          def value
            count(relation)
          end

          def relation
            Board.where(database_time_constraints)
          end
        end
      end
    end
  end
end
