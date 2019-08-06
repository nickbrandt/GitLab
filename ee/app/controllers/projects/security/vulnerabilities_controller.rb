# frozen_string_literal: true

class Projects::Security::VulnerabilitiesController < Projects::ApplicationController
  include SecurityDashboardsPermissions
  include VulnerabilitiesActions

  alias_method :vulnerable, :project
end
