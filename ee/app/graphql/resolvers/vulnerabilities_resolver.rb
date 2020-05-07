# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesResolver < BaseResolver
    include Gitlab::Utils::StrongMemoize

    type Types::VulnerabilityType, null: true

    argument :project_id, [GraphQL::ID_TYPE],
             required: false,
             description: 'Filter vulnerabilities by project'

    argument :report_type, [Types::VulnerabilityReportTypeEnum],
             required: false,
             description: 'Filter vulnerabilities by report type'

    argument :severity, [Types::VulnerabilitySeverityEnum],
             required: false,
             description: 'Filter vulnerabilities by severity'

    argument :state, [Types::VulnerabilityStateEnum],
             required: false,
             description: 'Filter vulnerabilities by state'

    def resolve(**args)
      return Vulnerability.none unless vulnerable

      vulnerabilities(args).with_findings.ordered
    end

    private

    # `vulnerable` will be a Project, Group, or InstanceSecurityDashboard
    def vulnerable
      # A project or group could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project or group to query for vulnerabilities, so
      # make sure it's loaded and not `nil` before continuing.

      strong_memoize(:vulnerable) do
        if resolve_vulnerabilities_for_instance_security_dashboard?
          ::InstanceSecurityDashboard.new(current_user)
        elsif object.respond_to?(:sync)
          object.sync
        else
          object
        end
      end
    end

    def vulnerabilities(filters)
      Security::VulnerabilitiesFinder.new(vulnerable, filters).execute
    end

    def resolve_vulnerabilities_for_instance_security_dashboard?
      # object will be nil when we're fetching vulnerabilities from QueryType,
      # which is the source of vulnerability data for the instance security
      # dashboard
      object.nil? && current_user.present?
    end
  end
end
