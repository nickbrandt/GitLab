# frozen_string_literal: true

module Projects
  module Security
    class SastConfigurationController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action :ensure_sast_configuration_enabled!

      def show
      end

      private

      def ensure_sast_configuration_enabled!
        not_found unless ::Feature.enabled?(:sast_configuration_ui, project)
      end
    end
  end
end
