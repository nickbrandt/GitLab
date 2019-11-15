# frozen_string_literal: true

module Epics
  class CreateService < Epics::BaseService
    def execute
      @epic = group.epics.new(whitelisted_epic_params)
      @epic.move_to_start if @epic.parent

      create(@epic)
    end

    private

    def before_create(epic)
      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      epic.run_after_commit do
        NewEpicWorker.perform_async(epic.id, user.id)
      end
    end

    def whitelisted_epic_params
      result = params.slice(:title, :description, :label_ids, :parent_id)

      if params[:start_date_fixed] && params[:start_date_is_fixed]
        result[:start_date] = params[:start_date_fixed]
      end

      if params[:due_date_fixed] && params[:due_date_is_fixed]
        result[:end_date] = params[:due_date_fixed]
      end

      result
    end
  end
end
