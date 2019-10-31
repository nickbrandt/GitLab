# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  before_action :check_license_admin_audit_log_available!
  before_action :validate_date_params

  PER_PAGE = 25

  def index
    @events = AuditLogFinder.new(audit_logs_params).execute.page(params[:page]).per(PER_PAGE)
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

  def audit_logs_params
    params.permit(:entity_type, :entity_id, :created_before, :created_after)
  end

  def check_license_admin_audit_log_available!
    render_404 unless License.feature_available?(:admin_audit_log)
  end

  def validate_date_params
    unless valid_utc_date?(params[:created_before]) && valid_utc_date?(params[:created_after])
      flash[:alert] = _('Invalid date format. Please use UTC format as YYYY-MM-DD')
    end
  end

  def valid_utc_date?(date)
    date.blank? || date =~ Gitlab::Regex.utc_date_regex
  end
end
