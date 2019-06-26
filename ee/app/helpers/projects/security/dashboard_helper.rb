# frozen_string_literal: true

module Projects
  module Security
    module DashboardHelper
      def can_read_project_security_dashboard?(project)
        can?(current_user, :read_project_security_dashboard, project)
      end
    end
  end
end
