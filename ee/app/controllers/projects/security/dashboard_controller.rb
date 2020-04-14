# frozen_string_literal: true

module Projects
  module Security
    class DashboardController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action only: [:index] do
        push_frontend_feature_flag(:hide_dismissed_vulnerabilities)
        push_frontend_feature_flag(:first_class_vulnerabilities, @project, default_enabled: true)
      end

      def index
        @pipeline = @project.latest_pipeline_with_security_reports
          &.present(current_user: current_user)
      end
    end
  end
end
