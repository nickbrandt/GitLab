# frozen_string_literal: true

module EE
  module BoardsResponses
    extend ActiveSupport::Concern

    def authorize_read_parent
      authorize_action_for!(board, :read_parent)
    end

    def authorize_read_milestone
      authorize_action_for!(board, :read_milestone)
    end
  end
end
