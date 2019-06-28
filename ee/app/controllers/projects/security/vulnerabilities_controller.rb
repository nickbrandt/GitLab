# frozen_string_literal: true

class Projects::Security::VulnerabilitiesController < Projects::ApplicationController
  include VulnerabilitiesActions

  alias_method :vulnerable, :project

  before_action :authorize_read_project_security_dashboard!

  private

  def authorize_read_project_security_dashboard!
    render_403 unless helpers.can_read_project_security_dashboard?(project)
  end
end
