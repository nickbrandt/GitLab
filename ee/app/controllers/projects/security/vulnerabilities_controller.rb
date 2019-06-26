# frozen_string_literal: true

class Projects::Security::VulnerabilitiesController < Projects::ApplicationController
  before_action :ensure_security_dashboard_feature_enabled!
  before_action :authorize_read_project_security_dashboard!

  def index
  end

  def summary
  end

  def history
  end

  private

  def ensure_security_dashboard_feature_enabled!
    render_404 unless project.feature_available?(:security_dashboard)
  end

  def authorize_read_project_security_dashboard!
    render_403 unless helpers.can_read_project_security_dashboard?(project)
  end
end
