# frozen_string_literal: true

module Epics
  module Strategies
    class DueDateInheritedStrategy < BaseDatesStrategy
      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        @epics.due_date_inherited.update_all(
          [
            %{ (end_date, due_date_sourcing_milestone_id, due_date_sourcing_epic_id) = (?) },
            ::Epic.from_union([max_milestone_due_date, max_child_epics_end_date], alias_as: 'max_date')
              .select('max_end_date', 'milestone_id', 'epic_id')
              .order("max_end_date desc")
              .limit(1)
          ]
        )
      end

      private

      def max_milestone_due_date
        source_milestones_query
          .where.not(due_date: nil)
          .select(
            "milestones.due_date AS max_end_date",
            "NULL AS epic_id",
            "milestones.id AS milestone_id")
      end

      def max_child_epics_end_date
        epic_dates = ::Epic.arel_table.alias('epic_dates')

        ::Epic
          .where.not(epic_dates: { end_date: nil })
          .where("epic_dates.parent_id = epics.id")
          .select(
            "epic_dates.end_date AS max_end_date",
            "epic_dates.id AS epic_id",
            "NULL AS milestone_id")
          .from(epic_dates)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
