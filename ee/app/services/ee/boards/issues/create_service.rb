# frozen_string_literal: true

module EE
  module Boards
    module Issues
      module CreateService
        extend ::Gitlab::Utils::Override

        override :issue_params
        def issue_params
          super.tap do |options|
            assignee_ids = Array(list.user_id || board.assignee&.id)
            milestone_id = list.milestone_id || board.milestone_id

            options[:label_ids].concat(board.label_ids)
            options[:weight] = board.weight if valid_weight?

            options.merge!(
              milestone_id: milestone_id,
              # This can be removed when boards have multiple assignee support.
              # See https://gitlab.com/gitlab-org/gitlab/issues/3786
              assignee_ids: assignee_ids)
          end
        end

        def valid_weight?
          board.weight.present? && board.weight >= 0
        end
      end
    end
  end
end
