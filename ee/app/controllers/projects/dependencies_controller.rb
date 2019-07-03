# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    before_action :check_feature_enabled!

    before_action do
      push_frontend_feature_flag(:dependency_list_vulnerabilities)
    end

    def check_feature_enabled!
      render_404 unless project.feature_available?(:dependency_list)
    end
  end
end
