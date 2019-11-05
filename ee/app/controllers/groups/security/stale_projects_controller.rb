# frozen_string_literal: true

class Groups::Security::StaleProjectsController < Groups::ApplicationController
  include SecurityDashboardsPermissions

  alias_method :vulnerable, :group

  def index
    render json: stale_projects
  end

  private

  def stale_projects
    group.projects
    # joins builds
    # where there are no builds with security reports
    # OR where the latest successful builds with security reports finished 6 or more days ago
  end
end
