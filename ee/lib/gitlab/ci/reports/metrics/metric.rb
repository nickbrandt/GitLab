# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Metrics
        class Metric
          attr_reader :name
          attr_reader :value

          def initialize(name, value)
            @name = name
            @value = value
          end
        end
      end
    end
  end
end
