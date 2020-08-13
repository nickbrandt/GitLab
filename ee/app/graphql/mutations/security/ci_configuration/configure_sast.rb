# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSast < BaseMutation
        include ResolvesProject

        graphql_name 'ConfigureSast'

        argument :project_path, GraphQL::ID_TYPE,
          required: true,
          description: 'Full path of the project.'

        argument :configuration, GraphQL::Types::JSON,
          required: true,
          description: 'Payload containing SAST variable values (https://docs.gitlab.com/ee/user/application_security/sast/#available-variables).'

        field :result,
          GraphQL::Types::JSON,
          null: true,
          description: 'JSON containing the status of MR creation.'

        authorize :push_code

        def resolve(project_path:, configuration:)
          project = authorized_find!(full_path: project_path)
          format_json(::Security::CiConfiguration::SastCreateService.new(project, current_user, configuration).execute)
        end

        private

        def find_object(full_path:)
          resolve_project(full_path: full_path)
        end

        def format_json(result)
          {
            result: {
              status: result[:status],
              success_path: result[:success_path],
              errors: result[:errors]
            }
          }
        end
      end
    end
  end
end
