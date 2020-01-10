# frozen_string_literal: true

module Security
  class ApplicationController < ::ApplicationController
    before_action :authorize_read_security_dashboard!
    before_action do
      push_frontend_feature_flag(:security_dashboard, default_enabled: true)
    end

    private

    def authorize_read_security_dashboard!
      render_404 unless Feature.enabled?(:security_dashboard, default_enabled: true) &&
        can?(current_user, :read_security_dashboard)
    end
  end
end
