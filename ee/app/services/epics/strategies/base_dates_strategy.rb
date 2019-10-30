# frozen_string_literal: true

module Epics
  module Strategies
    class BaseDatesStrategy
      def initialize(epics)
        @epics = epics
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def source_milestones_query
        ::Milestone
          .joins(issues: :epic_issue)
          .where("epic_issues.epic_id = epics.id")
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
