# frozen_string_literal: true

class Groups::AuditEventsController < Groups::ApplicationController
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditLogsParams
  include AuditEvents::Sortable

  before_action :authorize_admin_group!
  before_action :check_audit_events_available!

  layout 'group_settings'

  def index
    level = Gitlab::Audit::Levels::Group.new(group: group)

    events = AuditLogFinder
      .new(level: level, params: audit_logs_params)
      .execute
      .page(params[:page])
      .without_count

    @events = Gitlab::Audit::Events::Preloader.preload!(events)
  end
end
