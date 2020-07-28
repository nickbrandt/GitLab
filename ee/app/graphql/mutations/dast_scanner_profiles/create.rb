# frozen_string_literal: true

module Mutations
  module DastScannerProfiles
    class Create < BaseMutation
      include ResolvesProject

      graphql_name 'DastScannerProfileCreate'

      field :id, GraphQL::ID_TYPE,
            null: true,
            description: 'ID of the scanner profile.'

      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project the scanner profile belongs to.'

      argument :profile_name, GraphQL::STRING_TYPE,
                required: true,
                description: 'The name of the scanner profile.'

      argument :spider_timeout, GraphQL::INT_TYPE,
                required: false,
                description: 'The maximum number of seconds allowed for the spider to traverse the site.'

      argument :target_timeout, GraphQL::INT_TYPE,
                required: false,
                description: 'The maximum number of seconds allowed for the site under test to respond to a request.'

      authorize :run_ondemand_dast_scan

      def resolve(full_path:, profile_name:, spider_timeout: nil, target_timeout: nil)
        project = authorized_find!(full_path: full_path)
        raise_resource_not_available_error! unless Feature.enabled?(:security_on_demand_scans_feature_flag, project)

        service = ::DastScannerProfiles::CreateService.new(project, current_user)
        result = service.execute(name: profile_name, spider_timeout: spider_timeout, target_timeout: target_timeout)

        if result.success?
          { id: result.payload.to_global_id, errors: [] }
        else
          { errors: result.errors }
        end
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end
    end
  end
end
