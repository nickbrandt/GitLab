# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersVisitingAnalyticsValuestreamMetric < BaseMetric
          def value
            redis_usage_data { count_unique_events }
          end

          def event_names
            :g_analytics_valuestream
          end

          def count_unique_events
            Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**time_constraints.merge(event_names: event_names))
          end
        end
      end
    end
  end
end
