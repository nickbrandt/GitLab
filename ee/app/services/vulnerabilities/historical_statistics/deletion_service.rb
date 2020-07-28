# frozen_string_literal: true

module Vulnerabilities
  module HistoricalStatistics
    class DeletionService
      def self.execute
        new.execute
      end

      def execute
        ::Vulnerabilities::HistoricalStatistic
          .older_than(days: 100)
          .each_batch { |relation| relation.delete_all }
      end
    end
  end
end
