# frozen_string_literal: true

module EE
  module Types
    module QueryType
      extend ActiveSupport::Concern

      # The design management context object needs to implement #issue
      DesignManagementObject = Struct.new(:issue)

      prepended do
        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: "Vulnerabilities reported on projects on the current user's instance security dashboard",
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :design_management, ::Types::DesignManagementType,
              null: false,
              description: 'Fields related to design management'

        field :geo_node, ::Types::Geo::GeoNodeType,
              null: true,
              resolver: ::Resolvers::Geo::GeoNodeResolver,
              description: 'Find a Geo node'

        field :instance_security_dashboard, ::Types::InstanceSecurityDashboardType,
              null: true,
              resolver: ::Resolvers::InstanceSecurityDashboardResolver,
              description: 'Fields related to Instance Security Dashboard'

        def design_management
          DesignManagementObject.new(nil)
        end
      end
    end
  end
end
