# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSast < BaseMutation
        include ResolvesProject

        graphql_name 'ConfigureSast'

        argument :project_path, GraphQL::ID_TYPE,
          required: true,
          description: 'Full path of the project'

        argument :configuration, ::Types::CiConfiguration::Sast::InputType,
          required: true,
          description: 'SAST CI configuration for the project'

        field :status, GraphQL::STRING_TYPE, null: false,
          description: 'Status of creating the commit for the supplied SAST CI configuration'

        field :success_path, GraphQL::STRING_TYPE, null: true,
          description: 'Redirect path to use when the response is successful'

        authorize :push_code

        def resolve(project_path:, configuration:)
          project = authorized_find!(full_path: project_path)

          sast_create_service_params = format_for_service(configuration)
          result = ::Security::CiConfiguration::SastCreateService.new(project, current_user, sast_create_service_params).execute
          prepare_response(result)
        end

        private

        def find_object(full_path:)
          resolve_project(full_path: full_path)
        end

        # Temporary formatting necessary for supporting REST API
        # Will be removed during the implementation of
        # https://gitlab.com/gitlab-org/gitlab/-/issues/246737
        def format_for_service(configuration)
          global_values = configuration["global"]&.collect {|k| [k["field"], k["value"]]}.to_h
          pipeline_values = configuration["pipeline"]&.collect {|k| [k["field"], k["value"]]}.to_h
          global_values.merge!(pipeline_values)
        end

        def prepare_response(result)
          {
            status: result[:status],
            success_path: result[:success_path],
            errors: Array(result[:errors])
          }
        end
      end
    end
  end
end
