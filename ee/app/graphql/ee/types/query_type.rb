# frozen_string_literal: true

module EE
  module Types
    module QueryType
      extend ActiveSupport::Concern

      prepended do
        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: "Vulnerabilities reported on projects on the current user's instance security dashboard",
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerabilities_count_by_day_and_severity,
              ::Types::VulnerabilitiesCountByDayAndSeverityType.connection_type,
              null: true,
              description: "Number of vulnerabilities per severity level, per day, for the projects on the current user's instance security dashboard",
              resolver: ::Resolvers::VulnerabilitiesHistoryResolver

        field :geo_node, ::Types::Geo::GeoNodeType,
              null: true,
              resolver: ::Resolvers::Geo::GeoNodeResolver,
              description: 'Find a Geo node'

        field :instance_security_dashboard, ::Types::InstanceSecurityDashboardType,
              null: true,
              resolver: ::Resolvers::InstanceSecurityDashboardResolver,
              description: 'Fields related to Instance Security Dashboard'
      end
    end
  end
end
