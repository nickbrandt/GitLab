# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      def show
        @configuration = ConfigurationPresenter.new(project)
      end
    end
  end
end
