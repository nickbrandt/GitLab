# frozen_string_literal: true

module Projects
  module Security
    class VulnerabilitiesController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      def index
        return render_404 unless Feature.enabled?(:first_class_vulnerabilities, project)

        @vulnerabilities = Kaminari.paginate_array(project.vulnerabilities).page(params[:page])
      end
    end
  end
end
