# frozen_string_literal: true

module EE
  module BoardsResponses
    extend ActiveSupport::Concern

    def authorize_read_parent
      ability = board.group_board? ? :read_group : :read_project

      authorize_action_for!(board.parent, ability)
    end

    def authorize_read_milestone
      ability = board.group_board? ? :read_group : :read_milestone

      authorize_action_for!(board.parent, ability)
    end
  end
end
