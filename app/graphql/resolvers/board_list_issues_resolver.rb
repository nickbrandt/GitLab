# frozen_string_literal: true

module Resolvers
  class BoardListIssuesResolver < BaseResolver
    type Types::IssueType, null: true

    alias_method :list, :object

    def resolve(**args)
      # rubocop: disable CodeReuse/ActiveRecord
      service = Boards::Issues::ListService.new(list.board.resource_parent, context[:current_user], { board_id: list.board.id, id: list.id })
      service.execute.reorder("relative_position ASC")
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
