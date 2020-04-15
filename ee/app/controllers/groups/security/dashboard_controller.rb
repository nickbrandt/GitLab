# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::ApplicationController
  layout 'group'

  before_action only: [:show] do
    push_frontend_feature_flag(:first_class_vulnerabilities, group, default_enabled: true)
  end

  def show
    render :unavailable unless dashboard_available?
  end

  private

  def dashboard_available?
    group.feature_available?(:security_dashboard) &&
      can?(current_user, :read_group_security_dashboard, group)
  end
end
