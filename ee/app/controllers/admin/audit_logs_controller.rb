# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditLogsParams

  before_action :check_license_admin_audit_log_available!

  PER_PAGE = 25

  def index
    @events = audit_log_events.page(params[:page]).per(PER_PAGE).without_count

    @entity = case audit_logs_params[:entity_type]
              when 'User'
                User.find_by_id(audit_logs_params[:entity_id])
              when 'Project'
                Project.find_by_id(audit_logs_params[:entity_id])
              when 'Group'
                Namespace.find_by_id(audit_logs_params[:entity_id])
              else
                nil
              end
  end

  private

  def audit_log_events
    AuditLogFinder.new(audit_logs_params).execute
  end

  def check_license_admin_audit_log_available!
    render_404 unless License.feature_available?(:admin_audit_log)
  end
end
