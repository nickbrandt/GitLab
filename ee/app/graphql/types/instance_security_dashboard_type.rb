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
  end
end
