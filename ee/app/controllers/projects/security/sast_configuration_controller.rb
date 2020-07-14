# frozen_string_literal: true

module Projects
  module Security
    class SastConfigurationController < Projects::ApplicationController
      include CreatesCommit
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action :ensure_sast_configuration_enabled!
      before_action :authorize_edit_tree!, only: [:create]

      def show
      end

      def create
        @branch_name = project.repository.next_branch("add-sast-config")

        @commit_params = {
          commit_message: "Add .gitlab-ci.yml to enable SAST",
          actions: [{ action: "create", file_path: ".gitlab-ci.yml", content: gitlab_ci_yml }]
        }

        project.repository.add_branch(current_user, @branch_name, project.default_branch)

        create_commit(::Files::MultiService, success_notice: _("The .gitlab-ci.yml has been successfully created."),
                      success_path: successful_change_path, failure_path: '')
      end

      private

      def ensure_sast_configuration_enabled!
        not_found unless ::Feature.enabled?(:sast_configuration_ui, project)
      end

      def successful_change_path
        description = "Add .gitlab-ci.yml to enable SAST security scan using the GitLab managed SAST template."
        merge_request_params = { source_branch: @branch_name, description: description }
        project_new_merge_request_url(@project, merge_request: merge_request_params)
      end

      def gitlab_ci_yml
        return ado_yml if project.auto_devops_enabled?

        sast_yml
      end

      def ado_yml
        <<-CI_YML.strip_heredoc
          include:
            - template: Auto-DevOps.gitlab-ci.yml
        CI_YML
      end

      def sast_yml
        <<-CI_YML.strip_heredoc
          stages:
            - test

          include:
            - template: SAST.gitlab-ci.yml
        CI_YML
      end
    end
  end
end
