# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesResolver < VulnerabilitiesBaseResolver
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

    argument :scanner, [GraphQL::STRING_TYPE],
             required: false,
             description: 'Filter vulnerabilities by scanner'

    def resolve(**args)
      return Vulnerability.none unless vulnerable

      vulnerabilities(args).with_findings.ordered
    end

    private

    def vulnerabilities(filters)
      Security::VulnerabilitiesFinder.new(vulnerable, filters).execute
    end
  end
end
