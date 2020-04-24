# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action only: [:show] do
        push_frontend_feature_flag(:suggested_solution)
      end

      def show
        @configuration = ConfigurationPresenter.new(project)
      end
    end
  end
end
