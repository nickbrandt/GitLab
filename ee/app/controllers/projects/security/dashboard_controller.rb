# frozen_string_literal: true

module Projects
  module Security
    class DashboardController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action only: [:index] do
        push_frontend_feature_flag(:hide_dismissed_vulnerabilities)
      end

      def index
        @pipeline = @project.latest_pipeline_with_security_reports
          &.present(current_user: current_user)
      end

      def show
        return render_404 unless Feature.enabled?(:first_class_vulnerabilities, project)

        @vulnerability = project.vulnerabilities.find(params[:id])
        pipeline = @vulnerability.finding.pipelines.first
        @pipeline = pipeline if Ability.allowed?(current_user, :read_pipeline, pipeline)
      end
    end
  end
end
