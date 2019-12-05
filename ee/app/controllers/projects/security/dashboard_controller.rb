# frozen_string_literal: true

module Projects
  module Security
    class DashboardController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      def show
        @pipeline = @project.latest_pipeline_with_security_reports
          &.present(current_user: current_user)
      end
    end
  end
end
