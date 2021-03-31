# frozen_string_literal: true

module Mutations
  module AppSec
    module CiConfiguration
      class ConfigureDependencyScanning < BaseMutation
        include FindsProject

        graphql_name 'ConfigureDependencyScanning'

        argument :project_path, GraphQL::ID_TYPE,
                 required: true,
                 description: 'Full path of the project.'

        field :success_path, GraphQL::STRING_TYPE, null: true,
              description: 'Redirect path to use when the response is successful.'

        authorize :push_code #change to some more precise

        def resolve(project_path:)
          project = authorized_find!(project_path)

          result = ::Security::CiConfiguration::DependencyScanningCreateService.new(project, current_user, configuration).execute
          prepare_response(result)
        end

        private

        def prepare_response(result)
          {
            success_path: result[:success_path],
            errors: Array(result[:errors])
          }
        end
      end
    end
  end
end
