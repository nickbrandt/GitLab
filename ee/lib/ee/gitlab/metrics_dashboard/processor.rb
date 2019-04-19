# frozen_string_literal: true

module EE
  module Gitlab
    module MetricsDashboard
      module Processor
        def sequence
          super + [Stages::AlertsInserter]
        end
      end
    end
  end
end
