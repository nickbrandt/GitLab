# frozen_string_literal: true

module Gitlab
  module UsageCounters
    class DependencyList < Common
      def self.base_key
        'DEPENDENCY_LIST_USAGE_COUNTER'
      end
    end
  end
end
