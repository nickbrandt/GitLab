# frozen_string_literal: true

module EE
  module API
    module Entities
      module Project
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :preload_relation
          def preload_relation(projects_relation, options = {})
            super(projects_relation).with_compliance_framework_settings
          end
        end

        prepended do
          expose :approvals_before_merge, if: ->(project, _) { project.feature_available?(:merge_request_approvers) }
          expose :mirror, if: ->(project, _) { project.feature_available?(:repository_mirrors) }
          expose :mirror_user_id, if: ->(project, _) { project.mirror? }
          expose :mirror_trigger_builds, if: ->(project, _) { project.mirror? }
          expose :only_mirror_protected_branches, if: ->(project, _) { project.mirror? }
          expose :mirror_overwrites_diverged_branches, if: ->(project, _) { project.mirror? }
          expose :external_authorization_classification_label,
                 if: ->(_, _) { License.feature_available?(:external_authorization_service_api_management) }
          expose :packages_enabled
          expose :service_desk_enabled
          expose :service_desk_address
          expose :marked_for_deletion_at, if: ->(project, _) { project.feature_available?(:adjourned_deletion_for_projects_and_groups) }
          expose :marked_for_deletion_on, if: ->(project, _) { project.feature_available?(:adjourned_deletion_for_projects_and_groups) } do |project, _|
            project.marked_for_deletion_at
          end
          expose :compliance_frameworks do |project, _|
            [project.compliance_framework_setting&.framework].compact
          end
        end
      end
    end
  end
end
