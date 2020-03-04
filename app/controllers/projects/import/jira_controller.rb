# frozen_string_literal: true

module Projects
  module Import
    class JiraController < Projects::ApplicationController
      before_action :jira_import_enabled?
      before_action :jira_integration_configured?

      def show
        prev_imported_project_key = @project.import_data&.data&.dig("jira", "project", "key")
        @jira_projects = [prev_imported_project_key].compact

        unless @project.import_state&.in_progress? || prev_imported_project_key
          jira_client = @project.jira_service.client
          @jira_projects = jira_client.Project.all.map { |p| ["#{p.name}(#{p.key})", p.key] }
        end

        flash[:notice] = _("Import %{status}") % { status: @project.import_state.status } if @project.import_state.present? && !@project.import_state.none?
      end

      def import
        import_state = @project.import_state
        import_state = @project.create_import_state unless import_state.present?

        schedule_import(jira_import_params) unless import_state.in_progress?

        redirect_to project_import_jira_path(@project)
      end

      private

      def jira_integration_configured?
        unless @project.jira_service
          flash[:notice] = _("Configure Jira Integration first at Settings > Integrations > Jira")
          redirect_to project_issues_path(@project)
        end
      end

      def jira_import_enabled?
        redirect_to project_issues_path(@project) unless Feature.enabled?(:jira_issue_import, @project)
      end

      def schedule_import(params)
        return @project.import_state.schedule if @project.import_data

        jira_data = { jira: { project: { key: params[:jira_project_key] } } }
        @project.create_or_update_import_data(data: jira_data)
        @project.import_type = 'jira'
        @project.import_state.schedule if @project.save
      end

      def jira_import_params
        params.permit(:jira_project_key)
      end
    end
  end
end
