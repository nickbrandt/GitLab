# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersCreatingIssuesMetric < BaseMetric
          def value
            distinct_count(relation, column)
          end

          def column
            :author_id
          end

          def relation
            ::Issue.where(database_time_constraints)
          end
        end
      end
    end
  end
end
