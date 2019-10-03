# frozen_string_literal: true

class PlannedProjectDestroyWorker
  include ApplicationWorker
  include ExceptionBacktrace

  def perform(project_id)
    project = Project.find(project_id)
    user = project.deleting_user

    ::Projects::PlannedDestroyService.new(project, user).execute
  rescue ActiveRecord::RecordNotFound => error
    logger.error("Failed to delete project (#{project_id}): #{error.message}")
  end
end
