# frozen_string_literal: true
module EE
  module Gitlab
    module UsageDataCounters
      module HLLRedisCounter
        extend ActiveSupport::Concern
        class_methods do
          extend ::Gitlab::Utils::Override

          override :valid_context
          def valid_context
            super + License.all_plans
          end
        end
      end
    end
  end
end
