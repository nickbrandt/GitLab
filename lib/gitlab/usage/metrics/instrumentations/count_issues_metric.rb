# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesMetric < DatabaseMetric
          operation :count

          start do
            ::Issue.minimum(:id)
          end
          finish { ::Issue.maximum(:id) }

          relation do |database_time_constraints|
            ::Issue.where(database_time_constraints)
          end
        end
      end
    end
  end
end
