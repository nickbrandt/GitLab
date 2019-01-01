# frozen_string_literal: true

module Projects
  module Settings
    class OperationsController < Projects::ApplicationController
      before_action :check_license
      before_action :authorize_update_environment!

      def show
      end

      def update
        result = ::Projects::Operations::UpdateService.new(project, current_user, update_params).execute

        if result[:status] == :success
          flash[:notice] = _('Your changes have been saved')
          redirect_to project_settings_operations_path(@project)
        else
          render 'show'
        end
      end

      private

      helper_method :tracing_setting

      def tracing_setting
        @tracing_setting ||= project.tracing_setting || project.build_tracing_setting
      end

      def update_params
        params.require(:project).permit(tracing_setting_attributes: [:external_url])
      end

      def check_license
        render_404 unless @project.feature_available?(:tracing, current_user)
      end
    end
  end
end
