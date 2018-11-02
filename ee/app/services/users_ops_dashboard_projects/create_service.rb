# frozen_string_literal: true

module UsersOpsDashboardProjects
  class CreateService < UsersOpsDashboardProjects::BaseService
    Result = Struct.new(:added_project_ids, :invalid_project_ids, :duplicate_project_ids)

    def execute(project_ids)
      projects_to_add = load_projects(user, project_ids)

      invalid = find_invalid_ids(projects_to_add, project_ids)
      added, duplicate = add_projects(projects_to_add, user)

      Result.new(added.map(&:id), invalid, duplicate.map(&:id))
    end

    private

    def load_projects(current_user, project_ids)
      Dashboard::Operations::ProjectsService.new(current_user).execute(project_ids)
    end

    def find_invalid_ids(projects_to_add, project_ids)
      by_string_id = projects_to_add.index_by { |project| project.id.to_s }

      project_ids.reject { |id| by_string_id.key?(id.to_s) }
    end

    def add_projects(projects, user)
      projects.partition { |project| add_project(project, user) }
    end

    def add_project(project, user)
      user.ops_dashboard_projects << project
      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
