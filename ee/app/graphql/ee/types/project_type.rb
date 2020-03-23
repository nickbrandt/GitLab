# frozen_string_literal: true

module EE
  module Types
    module ProjectType
      extend ActiveSupport::Concern

      prepended do
        field :service_desk_enabled, GraphQL::BOOLEAN_TYPE, null: true,
              description: 'Indicates if the project has service desk enabled.'

        field :service_desk_address, GraphQL::STRING_TYPE, null: true,
              description: 'E-mail address of the service desk.'

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: 'Vulnerabilities reported on the project',
              resolver: Resolvers::VulnerabilitiesResolver,
              feature_flag: :first_class_vulnerabilities

        field :requirement, ::Types::RequirementType, null: true,
              description: 'Find a single requirement. Available only when feature flag `requirements_management` is enabled.',
              resolver: ::Resolvers::RequirementsResolver.single

        field :requirements, ::Types::RequirementType.connection_type, null: true,
              description: 'Find requirements. Available only when feature flag `requirements_management` is enabled.',
              max_page_size: 2000,
              resolver: ::Resolvers::RequirementsResolver
      end
    end
  end
end
