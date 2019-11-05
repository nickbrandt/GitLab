# frozen_string_literal: true

module Epics
  module Strategies
    class StartDateInheritedStrategy < BaseDatesStrategy
      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        @epics.start_date_inherited.update_all(
          [
            %{ (start_date, start_date_sourcing_milestone_id, start_date_sourcing_epic_id) = (?) },
            ::Epic.from_union([min_milestone_start_date, min_child_epics_start_date], alias_as: 'min_date')
              .select('min_start_date', 'milestone_id', 'epic_id')
              .order("min_start_date asc")
              .limit(1)
          ]
        )
      end

      private

      def min_milestone_start_date
        source_milestones_query
          .where.not(start_date: nil)
          .select(
            "milestones.start_date AS min_start_date",
            "NULL AS epic_id",
            "milestones.id AS milestone_id")
      end

      def min_child_epics_start_date
        epic_dates = ::Epic.arel_table.alias('epic_dates')

        ::Epic
          .where.not(epic_dates: { start_date: nil })
          .where("epic_dates.parent_id = epics.id")
          .select(
            "epic_dates.start_date AS min_start_date",
            "epic_dates.id AS epic_id",
            "NULL AS milestone_id")
          .from(epic_dates)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
