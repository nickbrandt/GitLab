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
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType, null: true,
               description: 'Counts for each severity of vulnerability of the project',
               resolve: -> (obj, _args, ctx) do
                 Hash.new(0).merge(
                   obj.vulnerabilities.with_states([:detected, :confirmed]).counts_by_severity
                 )
               end

        field :requirement, ::Types::RequirementType, null: true,
              description: 'Find a single requirement. Available only when feature flag `requirements_management` is enabled.',
              resolver: ::Resolvers::RequirementsResolver.single

        field :requirements, ::Types::RequirementType.connection_type, null: true,
              description: 'Find requirements. Available only when feature flag `requirements_management` is enabled.',
              resolver: ::Resolvers::RequirementsResolver

        field :requirement_states_count, ::Types::RequirementStatesCountType, null: true,
              description: 'Number of requirements for the project by their state',
              resolve: -> (project, args, ctx) do
                return unless requirements_available?(project, ctx[:current_user])

                Hash.new(0).merge(project.requirements.counts_by_state)
              end

        def self.requirements_available?(project, user)
          ::Feature.enabled?(:requirements_management, project, default_enabled: true) && Ability.allowed?(user, :read_requirement, project)
        end
      end
    end
  end
end
