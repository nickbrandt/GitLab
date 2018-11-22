# frozen_string_literal: true

module Dashboard
  module Operations
    class ProjectsService
      def initialize(user)
        @user = user
      end

      def execute(project_ids)
        return [] unless License.feature_available?(:operations_dashboard)

        find_projects(user, project_ids)
          .to_a
          .select { |project| project.feature_available?(:operations_dashboard) }
      end

      private

      attr_reader :user, :project_ids

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
