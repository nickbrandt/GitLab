# frozen_string_literal: true

module EE
  module Metrics
    module Dashboard
      module BaseService
        extend ::Gitlab::Utils::Override

        EE_SEQUENCE = [
          ::EE::Gitlab::Metrics::Dashboard::Stages::AlertsInserter
        ].freeze

        override :sequence
        def sequence
          super + EE_SEQUENCE
        end
      end
    end
  end
end
