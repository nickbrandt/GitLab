# frozen_string_literal: true

module Projects
  module PerformanceMonitoring
    class DashboardsController < ::Projects::ApplicationController
      include BlobHelper

      before_action :check_repository_available!
      before_action :validate_dashboard_template!
      before_action :authorize_push!

      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT
      DASHBOARD_TEMPLATES = {
        ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => true
      }.freeze

      def create
        result = ::Files::CreateService.new(project, current_user, dashboard_attrs).execute

        if result[:status] == :success
          respond_success
        else
          respond_error(result[:message])
        end
      end

      private

      def respond_success
        respond_to do |format|
          format.html { redirect_to ide_edit_path(project, branch, new_dashboard_path) }
          format.json { render json: { redirect_to: ide_edit_path(project, branch, new_dashboard_path) }, status: :created }
        end
      end

      def respond_error(message)
        flash[:alert] = message

        respond_to do |format|
          format.html { redirect_back_or_default(default: namespace_project_environments_path) }
          format.json { render json: { error: message }, status: :bad_request }
        end
      end

      def authorize_push!
        access_denied!(%q(You can't commit to this project)) unless user_access(project).can_push_to_branch?(branch)
      end

      def branch
        params.require(:branch)
      end

      def dashboard_attrs
        {
          commit_message: commit_message,
          file_path: new_dashboard_path,
          file_content: new_dashboard_content,
          encoding: 'text',
          branch_name: branch,
          start_branch: repository.branch_exists?(branch) ? branch : project.default_branch
        }
      end

      def commit_message
        params[:commit_message] || "Create custom dashboard #{params.require(:file_name)}"
      end

      def new_dashboard_path
        File.join(USER_DASHBOARDS_DIR, params.require(:file_name))
      end

      def new_dashboard_content
        File.read params.require(:dashboard)
      end

      def validate_dashboard_template!
        access_denied! unless dashboard_templates[params.require(:dashboard)]
      end

      def dashboard_templates
        DASHBOARD_TEMPLATES
      end
    end
  end
end

Projects::PerformanceMonitoring::DashboardsController.prepend_if_ee('EE::Projects::PerformanceMonitoring::DashboardsController')
