# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesResolver < BaseResolver
    include Gitlab::Utils::StrongMemoize

    type Types::VulnerabilityType, null: true

    def resolve(**args)
      return Vulnerability.none unless vulnerable

      vulnerable.vulnerabilities.with_findings.ordered
    end

    private

    # `vulnerable` will be a Project, Group, or InstanceSecurityDashboard
    def vulnerable
      # A project or group could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project or group to query for vulnerabilities, so
      # make sure it's loaded and not `nil` before continuing.

      strong_memoize(:vuln) do
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
