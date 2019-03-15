# frozen_string_literal: true
class Groups::Security::ApplicationController < Groups::ApplicationController
  before_action :ensure_security_dashboard_feature_enabled!
  before_action :authorize_read_group_security_dashboard!

  protected

  def ensure_security_dashboard_feature_enabled!
    render_404 unless group.feature_available?(:security_dashboard)
  end

  def authorize_read_group_security_dashboard!
    render_403 unless helpers.can_read_group_security_dashboard?(group)
  end
end
