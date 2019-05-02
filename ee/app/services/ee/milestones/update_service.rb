# frozen_string_literal: true

module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      # rubocop: disable CodeReuse/ActiveRecord
      def execute(milestone)
        super

        if saved_change_to_dates?(milestone)
          ::Epic.update_start_and_due_dates(
            ::Epic.joins(:issues).where(issues: { milestone_id: milestone.id })
          )
        end

        milestone
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def saved_change_to_dates?(milestone)
        milestone.saved_change_to_start_date? || milestone.saved_change_to_due_date?
      end
    end
  end
end
