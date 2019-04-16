# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Metrics
        class Report
          attr_reader :metrics

          def initialize
            @metrics = {}
          end

          def add_metric(key, value)
            @metrics[key] = value
          end
        end
      end
    end
  end
end
