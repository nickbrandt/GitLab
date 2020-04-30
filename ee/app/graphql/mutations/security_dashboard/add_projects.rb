# frozen_string_literal: true

module Mutations
  module SecurityDashboard
    class AddProjects < BaseMutation
      graphql_name 'AddProjectsToSecurityDashboard'

      authorize :read_instance_security_dashboard

      field :invalid_project_ids, [GraphQL::ID_TYPE],
            null: true,
            description: 'IDs of projects that were not added to the Instance Security Dashboard'

      field :added_project_ids, [GraphQL::ID_TYPE],
            null: true,
            description: 'IDs of projects that were added to the Instance Security Dashboard'

      field :duplicated_project_ids, [GraphQL::ID_TYPE],
            null: true,
            description: 'IDs of projects that are already added to the Instance Security Dashboard'

      argument :project_ids, [GraphQL::ID_TYPE],
               required: true,
               description: 'IDs of projects to be added to Instance Security Dashboard'

      def resolve(project_ids:)
        dashboard = authorized_find!
        raise_resource_not_available_error! unless dashboard.feature_available?(:security_dashboard)

        result = add_projects(project_ids.map(&method(:extract_project_id)))

        {
          invalid_project_ids: result.invalid_project_ids.map(&method(:to_global_id)),
          added_project_ids: result.added_project_ids.map(&method(:to_global_id)),
          duplicated_project_ids: result.duplicate_project_ids.map(&method(:to_global_id)),
          errors: []
        }
      end

      private

      def find_object(*args)
        InstanceSecurityDashboard.new(current_user)
      end

      def extract_project_id(global_id)
        return unless global_id.present?

        GitlabSchema.parse_gid(global_id, expected_type: ::Project).model_id
      end

      def add_projects(project_ids)
        Dashboard::Projects::CreateService.new(
          current_user,
          current_user.security_dashboard_projects,
          feature: :security_dashboard
        ).execute(project_ids.compact)
      end

      def to_global_id(project_id)
        GitlabSchema.id_from_object(Project.new(id: project_id))
      end
    end
  end
end
