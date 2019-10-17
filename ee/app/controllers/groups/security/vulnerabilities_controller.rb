# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::ApplicationController
  include VulnerabilitiesApiFeatureGate # must come first
  include SecurityDashboardsPermissions
  include VulnerabilityFindingsActions
  include VulnerabilityFindingsHistory

  alias_method :vulnerable, :group

  private

  def vulnerabilities_action_enabled?
    Feature.disabled?(:vulnerability_findings_api)
  end
end
