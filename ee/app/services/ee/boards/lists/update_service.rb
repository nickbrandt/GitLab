# frozen_string_literal: true

module EE
  module Boards
    module Lists
      module UpdateService
        extend ::Gitlab::Utils::Override

        private

        override :execute_by_params
        def execute_by_params(list)
          updated_max_issue_count = update_max_issue_count(list) if can_admin?(list)

          super || updated_max_issue_count
        end

        def max_issue_count?(list)
          params.has_key?(:max_issue_count) && list.board.resource_parent.feature_available?(:wip_limits)
        end

        def update_max_issue_count(list)
          return unless max_issue_count?(list)

          max_issue_count = params[:max_issue_count] || 0

          list.update(max_issue_count: max_issue_count)
        end
      end
    end
  end
end
