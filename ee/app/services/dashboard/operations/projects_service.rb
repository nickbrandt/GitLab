# frozen_string_literal: true

module Dashboard
  module Operations
    class ProjectsService
      def initialize(user)
        @user = user
      end

      def execute(project_ids, include_unavailable: false, limit: nil)
        return [] unless License.feature_available?(:operations_dashboard)

        projects = find_projects(user, project_ids).to_a
        projects = available_projects(projects) unless include_unavailable
        projects = limit ? projects.first(limit) : projects

        projects
      end

      private

      attr_reader :user, :project_ids

      def available_projects(projects)
        projects.select { |project| project.feature_available?(:operations_dashboard) }
      end

      def find_projects(user, project_ids)
        ProjectsFinder.new(
          current_user: user,
          project_ids_relation: project_ids,
          params: {
            min_access_level: ProjectMember::DEVELOPER
          }
        ).execute
      end
    end
  end
end
