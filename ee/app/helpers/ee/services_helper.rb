# frozen_string_literal: true

module EE
  module ServicesHelper
    extend ::Gitlab::Utils::Override

    override :project_jira_issues_integration?
    def project_jira_issues_integration?
      @project.jira_issues_integration_available? && @project.jira_service&.issues_enabled
    end

    override :integration_form_data
    def integration_form_data(integration, group: nil)
      form_data = super

      if integration.is_a?(JiraService)
        form_data.merge!(
          show_jira_issues_integration: @project&.jira_issues_integration_available?.to_s,
          show_jira_vulnerabilities_integration: integration.jira_vulnerabilities_integration_available?.to_s,
          enable_jira_issues: integration.issues_enabled.to_s,
          enable_jira_vulnerabilities: integration.jira_vulnerabilities_integration_enabled?.to_s,
          project_key: integration.project_key,
          vulnerabilities_issuetype: integration.vulnerabilities_issuetype,
          gitlab_issues_enabled: @project&.issues_enabled?.to_s,
          upgrade_plan_path: @project && ::Gitlab::CurrentSettings.should_check_namespace_plan? ? upgrade_plan_path(@project.group) : nil,
          edit_project_path: @project ? edit_project_path(@project, anchor: 'js-shared-permissions') : nil
        )
      end

      form_data
    end

    def add_to_slack_link(project, slack_app_id)
      "https://slack.com/oauth/authorize?scope=commands&client_id=#{slack_app_id}&redirect_uri=#{slack_auth_project_settings_slack_url(project)}&state=#{escaped_form_authenticity_token}"
    end

    def add_to_slack_data(projects)
      {
        projects: projects.as_json(only: [:id, :name]),
        sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
        is_signed_in: current_user.present?,
        slack_link_profile_slack_path: slack_link_profile_slack_path,
        gitlab_for_slack_gif_path: image_path('gitlab_for_slack.gif'),
        gitlab_logo_path: image_path('illustrations/gitlab_logo.svg'),
        slack_logo_path: image_path('illustrations/slack_logo.svg'),
        docs_path: help_page_path('user/project/integrations/gitlab_slack_application.md')
      }.to_json.html_safe
    end

    def escaped_form_authenticity_token
      CGI.escape(form_authenticity_token)
    end

    def jira_issues_show_data
      {
        issues_show_path: project_integrations_jira_issue_path(@project, params[:id], format: :json),
        issues_list_path: project_integrations_jira_issues_path(@project)
      }
    end
  end
end
