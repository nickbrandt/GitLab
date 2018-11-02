# frozen_string_literal: true

module UsersOpsDashboardProjects
  class DestroyService < UsersOpsDashboardProjects::BaseService
    def execute(project_id)
      remove_project(user, project_id)
    end

    private

    def remove_project(user, project_id)
      user.ops_dashboard_projects.destroy(project_id).first
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
