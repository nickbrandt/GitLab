# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    before_action :check_feature_enabled!

    def check_feature_enabled!
      render_404 unless ::Feature.enabled?(:dependency_list, default_enabled: false) &&
        project.feature_available?(:dependency_list)
    end
  end
end
