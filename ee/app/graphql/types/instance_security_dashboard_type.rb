# frozen_string_literal: true

module Types
  class InstanceSecurityDashboardType < BaseObject
    graphql_name 'InstanceSecurityDashboard'

    authorize :read_instance_security_dashboard

    field :projects,
          Types::ProjectType.connection_type,
          null: false,
          authorize: :read_project,
          description: 'Projects selected in Instance Security Dashboard'

    field :vulnerability_grades,
          Types::VulnerabilityGradesType,
          null: false,
          description: 'Represents vulnerable project counts for each grade',
          resolver: ::Resolvers::VulnerabilityGradesResolver
  end
end
