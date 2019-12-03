# frozen_string_literal: true

module Dashboard
  module Projects
    class ListService
      def initialize(user, feature:)
        @user = user
        @feature = feature
      end

      def execute(project_ids, include_unavailable: false, limit: nil)
        return [] unless License.feature_available?(feature)

        projects = find_projects(project_ids)
        projects = available_projects(projects) unless include_unavailable
        projects = limit ? projects.first(limit) : projects

        projects
      end

      private

      attr_reader :user, :feature

      def available_projects(projects)
        projects.select { |project| project.feature_available?(feature) }
      end

      def find_projects(project_ids)
        ProjectsFinder.new(
          current_user: user,
          project_ids_relation: project_ids,
          params: projects_finder_params
        ).execute
      end

      def projects_finder_params
        return {} if user.can?(:read_all_resources)

        {
          min_access_level: ProjectMember::DEVELOPER
        }
      end
    end
  end
end
