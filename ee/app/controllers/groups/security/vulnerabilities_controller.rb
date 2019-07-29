# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::ApplicationController
  include SecurityDashboardsPermissions
  include VulnerabilitiesActions

  alias_method :vulnerable, :group
end
