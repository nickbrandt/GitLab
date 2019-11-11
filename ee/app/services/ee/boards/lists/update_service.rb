# frozen_string_literal: true

module EE
  module Boards
    module Lists
      module UpdateService
        extend ::Gitlab::Utils::Override

        include MaxLimits

        private

        override :execute_by_params
        def execute_by_params(list)
          updated_max_limits = update_max_limits(list)

          super || updated_max_limits
        end

        def update_max_limits(list)
          return unless max_limits_update_possible?(list)

          list.update(list_max_limit_attributes_by_params)
        end

        def max_limits_update_possible?(list)
          max_limits_provided? && list.wip_limits_available? && can_admin?(list)
        end
      end
    end
  end
end
