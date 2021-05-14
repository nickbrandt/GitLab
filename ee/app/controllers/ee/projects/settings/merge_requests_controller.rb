# frozen_string_literal: true

module EE
  module Projects
    module Settings
      module MergeRequestsController
        extend ::Gitlab::Utils::Override
        extend ::ActiveSupport::Concern

        override :project_params_attributes
        def project_params_attributes
          super + project_params_ee
        end

        private

        override :project_setting_attributes
        def project_setting_attributes
          proj_setting_attrs = super + [:prevent_merge_without_jira_issue]

          if ::Feature.enabled?(:cve_id_request_button, project)
            proj_setting_attrs << :cve_id_request_enabled
          end

          proj_setting_attrs
        end

        def project_params_ee
          attrs = %i[
            approvals_before_merge
            approver_group_ids
            approver_ids
            merge_requests_template
            reset_approvals_on_push
            ci_cd_only
            use_custom_template
            require_password_to_approve
            group_with_project_templates_id
          ]

          attrs << %i[merge_pipelines_enabled] if allow_merge_pipelines_params?
          attrs << %i[merge_trains_enabled] if allow_merge_trains_params?

          attrs += merge_request_rules_params

          if project&.feature_available?(:auto_rollback)
            attrs << :auto_rollback_enabled
          end

          attrs
        end

        def mirror_params
          %i[
            mirror
            mirror_trigger_builds
          ]
        end

        def merge_request_rules_params
          attrs = []

          if can?(current_user, :modify_merge_request_committer_setting, project)
            attrs << :merge_requests_disable_committers_approval
          end

          if can?(current_user, :modify_approvers_rules, project)
            attrs << :disable_overriding_approvers_per_merge_request
          end

          if can?(current_user, :modify_merge_request_author_setting, project)
            attrs << :merge_requests_author_approval
          end

          attrs
        end

        def allow_merge_pipelines_params?
          project&.feature_available?(:merge_pipelines)
        end

        def allow_merge_trains_params?
          project&.feature_available?(:merge_trains)
        end
      end
    end
  end
end


