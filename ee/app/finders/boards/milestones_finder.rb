# frozen_string_literal: true

module Boards
  class MilestonesFinder
    def initialize(board, current_user = nil)
      @board = board
      @current_user = current_user
    end

    def execute
      finder_service.execute
    end

    private

    # rubocop: disable CodeReuse/Finder
    def finder_service
      parent = @board.resource_parent

      finder_params =
        if parent.is_a?(Group)
          {
            group_ids: parent.self_and_ancestors
          }
        else
          {
            project_ids: [parent.id],
            group_ids: parent.group&.self_and_ancestors
          }
        end

      ::MilestonesFinder.new(finder_params)
    end
    # rubocop: enable CodeReuse/Finder
  end
end
