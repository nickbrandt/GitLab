# frozen_string_literal: true

module Dashboard
  module Operations
    class ProjectsService
      def initialize(user)
        @user = user
      end

      def execute(project_ids)
        find_projects(user, project_ids)
      end

      private

      attr_reader :user, :project_ids

      def find_projects(user, project_ids)
        ProjectsFinder.new(
          current_user: user,
          project_ids_relation: project_ids,
          params: {
            plans: plan_names_for_operations_dashboard,
            min_access_level: ProjectMember::DEVELOPER
          }
        ).execute
      end

      def plan_names_for_operations_dashboard
        return unless Gitlab::CurrentSettings.should_check_namespace_plan?

        Namespace.plans_with_feature(:operations_dashboard)
      end
    end
  end
end
