# frozen_string_literal: true

module EE
  module Gitlab
    module MetricsDashboard
      module Processor
        def stages
          @stages ||= super + [Stages::AlertsInserter]
        end
      end
    end
  end
end
