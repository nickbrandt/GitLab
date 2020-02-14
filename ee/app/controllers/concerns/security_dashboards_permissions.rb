# frozen_string_literal: true

module SecurityDashboardsPermissions
  extend ActiveSupport::Concern

  included do
    before_action :ensure_security_dashboard_feature_enabled!
    before_action :authorize_read_security_dashboard!
  end

  protected

  def ensure_security_dashboard_feature_enabled!
    render_404 unless vulnerable.feature_available?(:security_dashboard)
  end

  def authorize_read_security_dashboard!
    render_403 unless can?(current_user, read_security_dashboard, vulnerable)
  end

  def read_security_dashboard
    "read_#{vulnerable.class.name.underscore}_security_dashboard".to_sym
  end
end
