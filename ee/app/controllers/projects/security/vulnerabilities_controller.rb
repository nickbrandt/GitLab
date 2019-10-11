# frozen_string_literal: true

class Projects::Security::VulnerabilitiesController < Projects::ApplicationController
  include VulnerabilitiesApiFeatureGate # must come first
  include SecurityDashboardsPermissions
  include VulnerabilityFindingsActions

  alias_method :vulnerable, :project

  private

  def vulnerabilities_action_enabled?
    Feature.disabled?(:first_class_vulnerabilities)
  end
end
