# frozen_string_literal: true

module Boards
  class ListService < Boards::BaseService
    def execute
      create_board! if parent.boards.empty?

      if parent.multiple_issue_boards_available?
        boards
      else
        # When multiple issue boards are not available
        # a user is only allowed to view the default shown board
        first_board
      end
    end

    private

    def boards
      parent.boards.order_by_name_asc
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def first_board
      # We could use just one query but MySQL does not support nested queries using LIMIT
      boards.where(id: boards.first).reorder(nil)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_board!
      Boards::CreateService.new(parent, current_user).execute
    end
  end
end
