# frozen_string_literal: true

module TodosActions
  extend ActiveSupport::Concern

  def create
    todo = TodoService.new.mark_todo(issuable, current_user)

    render json: {
      count: current_user.todos_pending_count,
      delete_path: dashboard_todo_path(todo)
    }
  end

  def destroy
    TodoService.new.resolve_todos_for_target(issuable, current_user, resolved_by_action: :mark_done)

    render json: {
      count: current_user.todos_pending_count
    }
  end
end
