# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action only: [:show] do
        push_frontend_feature_flag(:security_auto_fix, project, default_enabled: false)
      end

      def show
        @configuration = ConfigurationPresenter.new(project, auto_fix_permission: auto_fix_permission)
      end

      private

      def auto_fix_permission
        can?(current_user, :modify_auto_fix_setting, project)
      end
    end
  end
end
