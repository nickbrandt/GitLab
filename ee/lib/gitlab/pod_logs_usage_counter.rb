# frozen_string_literal: true

module Gitlab
  module PodLogsUsageCounter
    BASE_KEY = "POD_LOGS_USAGE_COUNTS"

    class << self
      def increment(project_id)
        Gitlab::Redis::SharedState.with { |redis| redis.hincrby(BASE_KEY, project_id, 1) }
      end

      def usage_totals
        Gitlab::Redis::SharedState.with do |redis|
          total_sum = 0

          totals = redis.hgetall(BASE_KEY).each_with_object({}) do |(project_id, count), result|
            total_sum += result[project_id.to_i] = count.to_i
          end

          totals[:total] = total_sum
          totals
        end
      end
    end
  end
end
