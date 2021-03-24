# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesMetric < BaseMetric
          def value
            count(relation, start: start, finish: finish)
          end

          def start
            ::Issue.minimum(:id)
          end

          def finish
            ::Issue.maximum(:id)
          end

          def relation
            ::Issue.where(database_time_constraints)
          end
        end
      end
    end
  end
end
