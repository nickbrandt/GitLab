# frozen_string_literal: true

module Gitlab
  # This class generates a non sql Usage Ping
  class UsageDataNoSql < UsageData
    UNCOMPUTED_METRIC = -2

    class << self
      def count(relation, column = nil, *rest)
        UNCOMPUTED_METRIC
      end

      def distinct_count(relation, column = nil, *rest)
        UNCOMPUTED_METRIC
      end

      def estimate_batch_distinct_count(relation, column = nil, *rest)
        UNCOMPUTED_METRIC
      end
    end
  end
end
