# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    before_action :authorize_read_dependency_list!

    def authorize_read_dependency_list!
      render_404 unless can?(current_user, :read_dependencies, project)
    end
  end
end
