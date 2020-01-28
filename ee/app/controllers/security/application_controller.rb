# frozen_string_literal: true

module Security
  class ApplicationController < ::ApplicationController
    include SecurityDashboardsPermissions

    before_action :check_feature_enabled!
    before_action do
      push_frontend_feature_flag(:security_dashboard, default_enabled: true)
    end

    protected

    def check_feature_enabled!
      render_404 unless Feature.enabled?(:security_dashboard, default_enabled: true)
    end

    def vulnerable
      @vulnerable ||= ApplicationInstance.new
    end
  end
end
