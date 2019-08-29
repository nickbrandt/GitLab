# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    before_action :authorize_read_dependency_list!

    before_action do
      push_frontend_feature_flag(:dependency_list_vulnerabilities, default_enabled: true)
    end

    def authorize_read_dependency_list!
      render_404 unless can?(current_user, :read_dependencies, project)
    end
  end
end
