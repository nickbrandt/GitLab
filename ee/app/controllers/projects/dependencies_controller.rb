# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    before_action :check_feature_enabled!

    def check_feature_enabled!
      render_404 unless project.feature_available?(:dependency_list)
    end
  end
end
