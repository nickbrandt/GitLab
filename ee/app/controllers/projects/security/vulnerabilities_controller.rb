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
    end
  end
end
