# frozen_string_literal: true

module Epics
  class ReopenService < Epics::BaseService
    def execute(epic)
      return epic unless can?(current_user, :update_epic, epic)

      reopen_epic(epic)
    end

    private

    def reopen_epic(epic)
      if epic.reopen
        SystemNoteService.change_status(epic, nil, current_user, epic.state)
        notification_service.reopen_epic(epic, current_user)
      end
    end
  end
end
