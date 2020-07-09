# frozen_string_literal: true

module EE
  module Types
    module ProjectType
      extend ActiveSupport::Concern

      prepended do
        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: 'Vulnerabilities reported on the project',
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability_scanners,
              ::Types::VulnerabilityScannerType.connection_type,
              null: true,
              description: 'Vulnerability scanners reported on the project vulnerabilties',
              resolver: ::Resolvers::Vulnerabilities::ScannersResolver

        field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType, null: true,
               description: 'Counts for each severity of vulnerability of the project',
               resolve: -> (obj, _args, ctx) do
                 Hash.new(0).merge(
                   obj.vulnerabilities.with_states([:detected, :confirmed]).counts_by_severity
                 )
               end

        field :requirement, ::Types::RequirementsManagement::RequirementType, null: true,
              description: 'Find a single requirement. Available only when feature flag `requirements_management` is enabled.',
              resolver: ::Resolvers::RequirementsManagement::RequirementsResolver.single

        field :requirements, ::Types::RequirementsManagement::RequirementType.connection_type, null: true,
              description: 'Find requirements. Available only when feature flag `requirements_management` is enabled.',
              resolver: ::Resolvers::RequirementsManagement::RequirementsResolver

        field :requirement_states_count, ::Types::RequirementsManagement::RequirementStatesCountType, null: true,
              description: 'Number of requirements for the project by their state',
              resolve: -> (project, args, ctx) do
                return unless requirements_available?(project, ctx[:current_user])

                Hash.new(0).merge(project.requirements.counts_by_state)
              end

        field :packages, ::Types::PackageType.connection_type, null: true,
              description: 'Packages of the project',
              resolver: ::Resolvers::PackagesResolver

        field :compliance_frameworks, ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type,
              description: 'Compliance frameworks associated with the project',
              resolver: ::Resolvers::ComplianceFrameworksResolver,
              null: true

        def self.requirements_available?(project, user)
          ::Feature.enabled?(:requirements_management, project, default_enabled: true) && Ability.allowed?(user, :read_requirement, project)
        end
      end
    end
  end
end
