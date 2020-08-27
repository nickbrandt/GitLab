# frozen_string_literal: true

module Mutations
  module InstanceSecurityDashboard
    class AddProject < BaseMutation
      graphql_name 'AddProjectToSecurityDashboard'

      authorize :developer_access

      field :project, Types::ProjectType,
            null: true,
            description: 'Project that was added to the Instance Security Dashboard'

      field :errors, [Types::ErrorType],
            null: false,
            description: 'Enhanced errors encountered during execution of the mutation.'

      field :error_messages, [GraphQL::STRING_TYPE],
            null: false,
            description: 'Errors encountered during execution of the mutation.'

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'ID of the project to be added to Instance Security Dashboard'

      def resolve(id:)
        project = authorized_find!(id: id)
        result = add_project(project)
        error_code, error_message = prepare_error_message_with_error_code(result, project)

        return { project: project, errors: [], error_messages: [] } if error_code.blank?

        {
          project: nil,
          errors: [extended_error(error_message, code: error_code.upcase)],
          error_messages: [error_message]
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
      end

      def prepare_error_message_with_error_code(result, project)
        return [] if result.added_project_ids.include?(project.id)

        if result.duplicate_project_ids.include?(project.id)
          [:duplicated, "Cannot add project #{project.name}. The project is already added to your Security Dashboard."]
        elsif result.not_licensed_project_ids.include?(project.id)
          [:not_licensed, "Cannot add project #{project.name}. Only projects created under a Gold license are available in Security Dashboards."]
        else
          [:not_found, 'Cannot add project. Project was not found or you don\'t have permission to add this project to Security Dashboards.']
        end
      end
    end
  end
end
