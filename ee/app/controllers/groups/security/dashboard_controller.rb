# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::Security::ApplicationController
  layout 'group'

  skip_before_action :ensure_security_dashboard_feature_enabled!, only: [:show]
  skip_before_action :authorize_read_group_security_dashboard!, only: [:show]

  def show
    render :unavailable unless dashboard_available?
  end

  private

  def dashboard_available?
    group.feature_available?(:security_dashboard) &&
      helpers.can_read_group_security_dashboard?(group)
  end
end
