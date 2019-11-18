# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::ApplicationController
  include VulnerabilitiesApiFeatureGate # must come first
  include SecurityDashboardsPermissions
  include VulnerabilityFindingsActions
  include VulnerabilityFindingsHistory

  alias_method :vulnerable, :group

  private

  # See the table below to understand the relation between first_class_vulnerabilities feature state and
  # Group Security Dashboard controller being used:
  #
  # | first_class_vulnerabilities | controller to use                     |
  # |---------------------------- | ------------------------------------- |
  # | enabled                     | groups/security/vulnerability_findings |
  # | disabled                    | groups/security/vulnerabilities        |
  #
  # The reason is that when first_class_vulnerabilities is enabled, Vulnerabilities name is reserved for
  # Standalone Vulnerabilities https://gitlab.com/gitlab-org/gitlab/issues/13561, and the entity that
  # was previously returned by Vulnerabilities-named endpoints get the name of Vulnerability Findings.
  # See also: https://gitlab.com/gitlab-org/gitlab/merge_requests/19029
  def vulnerabilities_action_enabled?
    Feature.disabled?(:first_class_vulnerabilities)
  end
end
