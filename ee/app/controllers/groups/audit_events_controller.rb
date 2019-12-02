# frozen_string_literal: true

class Groups::AuditEventsController < Groups::ApplicationController
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditLogsParams

  before_action :authorize_admin_group!
  before_action :check_audit_events_available!

  layout 'group_settings'

  def index
    @events = AuditLogFinder.new(audit_logs_params).execute.page(params[:page])
  end

  private

  def audit_logs_params
    super.merge(
      entity_type: group.class.name,
      entity_id: group.id
    )
  end
end
