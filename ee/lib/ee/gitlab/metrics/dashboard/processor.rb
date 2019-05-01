# frozen_string_literal: true

module EE
  module Gitlab
    module Metrics
      module Dashboard
        module Processor
          extend ::Gitlab::Utils::Override

          EE_SEQUENCE = [
            Stages::AlertsInserter
          ].freeze

          override :sequence
          def sequence(_insert_project_metrics)
            super + EE_SEQUENCE
          end
        end
      end
    end
  end
end
