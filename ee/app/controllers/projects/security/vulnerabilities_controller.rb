# frozen_string_literal: true

module Projects
  module Security
    class VulnerabilitiesController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      def index
        return render_404 unless Feature.enabled?(:first_class_vulnerabilities, project)

        @vulnerabilities = project.vulnerabilities.page(params[:page])
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
