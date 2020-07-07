# frozen_string_literal: true

module Vulnerabilities
  module Statistics
    class UpdateService
      def self.update_for(vulnerability)
        new(vulnerability).execute
      end

      def initialize(vulnerability)
        self.vulnerability = vulnerability
      end

      def execute

      end

      private

      attr_accessor :vulnerability

      def stat_diff
        @stat_diff ||= vulnerability.stat_diff
      end
    end
  end
end
