# frozen_string_literal: true

class Projects::AuditEventsController < Projects::ApplicationController
  include LicenseHelper
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditLogsParams
  include AuditEvents::Sortable

  before_action :authorize_admin_project!
  before_action :check_audit_events_available!

  layout 'project_settings'

  def index
    level = Gitlab::Audit::Levels::Project.new(project: project)

    events = AuditLogFinder
      .new(level: level, params: audit_logs_params)
      .execute
      .page(params[:page])

    @events = Gitlab::Audit::Events::Preloader.preload!(events)
  end

  private

  def check_audit_events_available!
    render_404 unless @project.feature_available?(:audit_events) || LicenseHelper.show_promotions?(current_user)
  end
end
