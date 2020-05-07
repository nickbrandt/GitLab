# frozen_string_literal: true

module Mutations
  module InstanceSecurityDashboard
    class AddProject < BaseMutation
      graphql_name 'AddProjectToSecurityDashboard'

      authorize :read_vulnerability

      field :project, Types::ProjectType,
            null: true,
            description: 'Project that was added to the Instance Security Dashboard'

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'ID of the project to be added to Instance Security Dashboard'

      def resolve(id:)
        project = authorized_find!(id: id)
        result = add_project(project)

        {
          project: result ? project : nil,
          errors: result ? [] : ['The project already belongs to your dashboard or you don\'t have permission to perform this action']
        }
      end

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id)
      end

      def add_project(project)
        Dashboard::Projects::CreateService
          .new(current_user, current_user.security_dashboard_projects, feature: :security_dashboard)
          .execute([project.id])
          .then { |result| result.added_project_ids.include?(project.id) }
      end
    end
  end
end
