# frozen_string_literal: true

module EE
  module API
    module Entities
      module EntityHelpers
        def can_read(attr, &block)
          ->(obj, opts) { Ability.allowed?(opts[:user], "read_#{attr}".to_sym, yield(obj)) }
        end

        def expose_restricted(attr, &block)
          expose attr, if: can_read(attr, &block)
        end
      end

      module UserPublic
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
          expose :extra_shared_runners_minutes_limit
        end
      end

      module UserWithAdmin
        extend ActiveSupport::Concern

        prepended do
          expose :note
        end
      end

      module Project
        extend ActiveSupport::Concern

        prepended do
          expose :repository_storage, if: ->(_project, options) { options[:current_user].try(:admin?) }
          expose :approvals_before_merge, if: ->(project, _) { project.feature_available?(:merge_request_approvers) }
          expose :mirror, if: ->(project, _) { project.feature_available?(:repository_mirrors) }
          expose :mirror_user_id, if: ->(project, _) { project.mirror? }
          expose :mirror_trigger_builds, if: ->(project, _) { project.mirror? }
          expose :only_mirror_protected_branches, if: ->(project, _) { project.mirror? }
          expose :mirror_overwrites_diverged_branches, if: ->(project, _) { project.mirror? }
          expose :external_authorization_classification_label,
                 if: ->(_, _) { License.feature_available?(:external_authorization_service_api_management) }
          expose :packages_enabled, if: ->(project, _) { project.feature_available?(:packages) }
        end
      end

      module Group
        extend ActiveSupport::Concern

        prepended do
          expose :ldap_cn, :ldap_access
          expose :ldap_group_links,
                 using: EE::API::Entities::LdapGroupLink,
                 if: ->(group, options) { group.ldap_group_links.any? }

          expose :checked_file_template_project_id,
                 as: :file_template_project_id,
                 if: ->(group, options) { group.feature_available?(:custom_file_templates_for_namespace) }
        end
      end

      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
          expose :extra_shared_runners_minutes_limit
        end
      end

      module Identity
        extend ActiveSupport::Concern

        prepended do
          expose :saml_provider_id
        end
      end

      module Member
        extend ActiveSupport::Concern

        prepended do
          expose :group_saml_identity,
                 using: ::API::Entities::Identity,
                 if:  -> (member, options) { Ability.allowed?(options[:current_user], :read_group_saml_identity, member.source) }
        end
      end

      module ProtectedRefAccess
        extend ActiveSupport::Concern

        prepended do
          expose :user_id
          expose :group_id
        end
      end

      module ProtectedBranch
        extend ActiveSupport::Concern

        prepended do
          expose :unprotect_access_levels, using: ::API::Entities::ProtectedRefAccess
          expose :code_owner_approval_required
        end
      end

      module IssueBasic
        extend ActiveSupport::Concern

        prepended do
          expose :weight, if: ->(issue, _) { issue.supports_weight? }
        end
      end

      module Issue
        extend ActiveSupport::Concern

        prepended do
          with_options if: -> (issue, options) { ::Ability.allowed?(options[:current_user], :read_epic, issue.project&.group) } do
            expose :epic_iid do |issue|
              issue.epic&.iid
            end

            expose :epic, using: EpicBaseEntity
          end
        end
      end

      module MergeRequestBasic
        extend ActiveSupport::Concern

        prepended do
          expose :approvals_before_merge
        end
      end

      module Namespace
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit, if: ->(_, options) { options[:current_user]&.admin? }
          expose :extra_shared_runners_minutes_limit, if: ->(_, options) { options[:current_user]&.admin? }
          expose :billable_members_count do |namespace, options|
            namespace.billable_members_count(options[:requested_hosted_plan])
          end
          expose :plan, if: ->(namespace, opts) { ::Ability.allowed?(opts[:current_user], :admin_namespace, namespace) } do |namespace, _|
            namespace.actual_plan_name
          end
        end
      end

      module Board
        extend ActiveSupport::Concern

        prepended do
          # Default filtering configuration
          expose :name
          expose :group, using: ::API::Entities::BasicGroupDetails

          with_options if: ->(board, _) { board.resource_parent.feature_available?(:scoped_issue_board) } do
            expose :milestone do |board|
              if board.milestone.is_a?(Milestone)
                ::API::Entities::Milestone.represent(board.milestone)
              else
                SpecialBoardFilter.represent(board.milestone)
              end
            end
            expose :assignee, using: ::API::Entities::UserBasic
            expose :labels, using: ::API::Entities::LabelBasic
            expose :weight
          end
        end
      end

      module List
        extend ActiveSupport::Concern

        prepended do
          expose :milestone, using: ::API::Entities::Milestone, if: -> (entity, _) { entity.milestone? }
          expose :user, as: :assignee, using: ::API::Entities::UserSafe, if: -> (entity, _) { entity.assignee? }
          expose :max_issue_count, if: -> (list, _) { list.wip_limits_available? }
          expose :max_issue_weight, if: -> (list, _) { list.wip_limits_available? }
        end
      end

      module ApplicationSetting
        extend ActiveSupport::Concern

        prepended do
          expose(*EE::ApplicationSettingsHelper.repository_mirror_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:repository_mirrors)
          end)
          expose :email_additional_text, if: ->(_instance, _opts) { ::License.feature_available?(:email_additional_text) }
          expose :file_template_project_id, if: ->(_instance, _opts) { ::License.feature_available?(:custom_file_templates) }
          expose :default_project_deletion_protection, if: ->(_instance, _opts) { ::License.feature_available?(:default_project_deletion_protection) }
        end
      end

      module Todo
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        override :todo_target_class
        def todo_target_class(target_type)
          super
        rescue NameError
          # false as second argument prevents looking up in module hierarchy
          # see also https://gitlab.com/gitlab-org/gitlab-foss/issues/59719
          ::EE::API::Entities.const_get(target_type, false)
        end

        override :todo_target_url
        def todo_target_url(todo)
          return super unless todo.target_type == ::DesignManagement::Design.name

          design = todo.target
          path_options = {
            anchor: todo_target_anchor(todo),
            vueroute: design.filename
          }

          ::Gitlab::Routing.url_helpers.designs_project_issue_url(design.project, design.issue, path_options)
        end
      end

      ########################
      # EE-specific entities #
      ########################
      module DesignManagement
        class Design < Grape::Entity
          expose :id
          expose :project_id
          expose :filename
          expose :image_url do |design|
            ::Gitlab::UrlBuilder.build(design)
          end
        end
      end

      class ProjectPushRule < Grape::Entity
        extend EntityHelpers
        expose :id, :project_id, :created_at
        expose :commit_message_regex, :commit_message_negative_regex, :branch_name_regex, :deny_delete_tag
        expose :member_check, :prevent_secrets, :author_email_regex
        expose :file_name_regex, :max_file_size
        expose_restricted :commit_committer_check, &:project
        expose_restricted :reject_unsigned_commits, &:project
      end

      class LdapGroupLink < Grape::Entity
        expose :cn, :group_access, :provider
      end

      class RelatedIssue < ::API::Entities::Issue
        expose :issue_link_id
      end

      class LinkedEpic < Grape::Entity
        expose :id
        expose :iid
        expose :title
        expose :group_id
        expose :parent_id
        expose :has_children?, as: :has_children
        expose :has_issues?, as: :has_issues
        expose :reference do |epic|
          epic.to_reference(epic.parent.group)
        end

        expose :url do |epic|
          ::Gitlab::Routing.url_helpers.group_epic_url(epic.group, epic)
        end

        expose :relation_url do |epic|
          ::Gitlab::Routing.url_helpers.group_epic_link_url(epic.parent.group, epic.parent.iid, epic.id)
        end
      end

      class AuditEvent < Grape::Entity
        expose :id
        expose :author_id
        expose :entity_id
        expose :entity_type
        expose :details do |audit_event|
          audit_event.formatted_details
        end
        expose :created_at
      end

      class Epic < Grape::Entity
        can_admin_epic = ->(epic, opts) { Ability.allowed?(opts[:user], :admin_epic, epic) }

        expose :id
        expose :iid
        expose :group_id
        expose :parent_id
        expose :title
        expose :description
        expose :author, using: ::API::Entities::UserBasic
        expose :start_date
        expose :start_date_is_fixed?, as: :start_date_is_fixed, if: can_admin_epic
        expose :start_date_fixed, :start_date_from_inherited_source, if: can_admin_epic
        expose :start_date_from_milestones, if: can_admin_epic # @deprecated in favor of start_date_from_inherited_source
        expose :end_date # @deprecated in favor of due_date
        expose :end_date, as: :due_date
        expose :due_date_is_fixed?, as: :due_date_is_fixed, if: can_admin_epic
        expose :due_date_fixed, :due_date_from_inherited_source, if: can_admin_epic
        expose :due_date_from_milestones, if: can_admin_epic # @deprecated in favor of due_date_from_inherited_source
        expose :state
        expose :web_edit_url, if: can_admin_epic # @deprecated
        expose :web_url
        expose :reference, if: { with_reference: true } do |epic|
          epic.to_reference(full: true)
        end
        expose :created_at
        expose :updated_at
        expose :closed_at
        expose :labels do |epic|
          # Avoids an N+1 query since labels are preloaded
          epic.labels.map(&:title).sort
        end
        expose :upvotes do |epic, options|
          if options[:issuable_metadata]
            # Avoids an N+1 query when metadata is included
            options[:issuable_metadata][epic.id].upvotes
          else
            epic.upvotes
          end
        end
        expose :downvotes do |epic, options|
          if options[:issuable_metadata]
            # Avoids an N+1 query when metadata is included
            options[:issuable_metadata][epic.id].downvotes
          else
            epic.downvotes
          end
        end

        # Calculating the value of subscribed field triggers Markdown
        # processing. We can't do that for multiple epics
        # requests in a single API request.
        expose :subscribed, if: -> (_, options) { options.fetch(:include_subscribed, false) } do |epic, options|
          user = options[:user]

          user.present? ? epic.subscribed?(user) : false
        end

        def web_url
          ::Gitlab::Routing.url_helpers.group_epic_url(object.group, object)
        end

        def web_edit_url
          ::Gitlab::Routing.url_helpers.group_epic_path(object.group, object)
        end
      end

      class EpicIssue < ::API::Entities::Issue
        expose :epic_issue_id
        expose :relative_position
      end

      class EpicIssueLink < Grape::Entity
        expose :id
        expose :relative_position
        expose :epic do |epic_issue_link, _options|
          ::EE::API::Entities::Epic.represent(epic_issue_link.epic, with_reference: true)
        end
        expose :issue, using: ::API::Entities::IssueBasic
      end

      class IssueLink < Grape::Entity
        expose :source, as: :source_issue, using: ::API::Entities::IssueBasic
        expose :target, as: :target_issue, using: ::API::Entities::IssueBasic
      end

      class SpecialBoardFilter < Grape::Entity
        expose :title
      end

      class ApprovalRuleShort < Grape::Entity
        expose :id, :name, :rule_type
      end

      class ApprovalRule < ApprovalRuleShort
        def initialize(object, options = {})
          presenter = ::ApprovalRulePresenter.new(object, current_user: options[:current_user])
          super(presenter, options)
        end

        expose :approvers, as: :eligible_approvers, using: ::API::Entities::UserBasic
        expose :approvals_required
        expose :users, using: ::API::Entities::UserBasic
        expose :groups, using: ::API::Entities::Group
        expose :contains_hidden_groups?, as: :contains_hidden_groups
      end

      class MergeRequestApprovalRule < ApprovalRule
        class SourceRule < Grape::Entity
          expose :approvals_required
        end

        expose :source_rule, using: SourceRule
      end

      class MergeRequestApprovalStateRule < MergeRequestApprovalRule
        expose :code_owner
        expose :approved_approvers, as: :approved_by, using: ::API::Entities::UserBasic
        expose :approved?, as: :approved
      end

      class MergeRequestApprovalState < Grape::Entity
        expose :approval_rules_overwritten do |approval_state|
          approval_state.approval_rules_overwritten?
        end

        expose :wrapped_approval_rules, as: :rules, using: MergeRequestApprovalStateRule
      end

      # Being used in private project-level approvals API.
      # This overrides the `eligible_approvers` to be exposed as `approvers`.
      #
      # To be removed in https://gitlab.com/gitlab-org/gitlab/issues/13574.
      class ApprovalSettingRule < ApprovalRule
        expose :approvers, using: ::API::Entities::UserBasic, override: true
      end

      # Being used in private project-level approvals API.
      #
      # To be removed in https://gitlab.com/gitlab-org/gitlab/issues/13574.
      class ProjectApprovalSettings < Grape::Entity
        expose :visible_approval_rules, as: :rules, using: ApprovalSettingRule
        expose :min_fallback_approvals, as: :fallback_approvals_required
      end

      # Being used in private MR-level approvals API.
      # This overrides the `eligible_approvers` to be exposed as `approvers`.
      #
      # To be removed in https://gitlab.com/gitlab-org/gitlab/issues/13574.
      class MergeRequestApprovalSettingRule < MergeRequestApprovalStateRule
        expose :approvers, using: ::API::Entities::UserBasic, override: true
      end

      # Being used in private MR-level approvals API.
      # This overrides the `rules` to be exposed using MergeRequestApprovalSettingRule.
      #
      # To be removed in https://gitlab.com/gitlab-org/gitlab/issues/13574.
      class MergeRequestApprovalSettings < MergeRequestApprovalState
        expose :wrapped_approval_rules, as: :rules, using: MergeRequestApprovalSettingRule, override: true
      end

      # @deprecated
      class Approver < Grape::Entity
        expose :user, using: ::API::Entities::UserBasic
      end

      # @deprecated
      class ApproverGroup < Grape::Entity
        expose :group, using: ::API::Entities::Group
      end

      class ApprovalSettings < Grape::Entity
        expose :approvers, using: EE::API::Entities::Approver
        expose :approver_groups, using: EE::API::Entities::ApproverGroup
        expose :approvals_before_merge
        expose :reset_approvals_on_push
        expose :disable_overriding_approvers_per_merge_request
        expose :merge_requests_author_approval
        expose :merge_requests_disable_committers_approval
      end

      class Approvals < Grape::Entity
        expose :user, using: ::API::Entities::UserBasic
      end

      class ApprovalState < Grape::Entity
        expose :merge_request, merge: true, using: ::API::Entities::IssuableEntity
        expose(:merge_status) { |approval_state| approval_state.merge_request.merge_status }

        expose :approved?, as: :approved

        expose :approvals_required

        expose :approvals_left

        expose :require_password_to_approve do |approval_state|
          approval_state.project.require_password_to_approve?
        end

        expose :approved_by, using: EE::API::Entities::Approvals do |approval_state|
          approval_state.merge_request.approvals
        end

        expose :suggested_approvers, using: ::API::Entities::UserBasic do |approval_state, options|
          approval_state.suggested_approvers(current_user: options[:current_user])
        end

        # @deprecated, reads from first regular rule instead
        expose :approvers do |approval_state|
          if rule = approval_state.first_regular_rule
            rule.users.map do |user|
              { user: ::API::Entities::UserBasic.represent(user) }
            end
          else
            []
          end
        end
        # @deprecated, reads from first regular rule instead
        expose :approver_groups do |approval_state|
          if rule = approval_state.first_regular_rule
            presenter = ::ApprovalRulePresenter.new(rule, current_user: options[:current_user])
            presenter.groups.map do |group|
              { group: ::API::Entities::Group.represent(group) }
            end
          else
            []
          end
        end

        expose :user_has_approved do |approval_state, options|
          approval_state.has_approved?(options[:current_user])
        end

        expose :user_can_approve do |approval_state, options|
          approval_state.can_approve?(options[:current_user])
        end

        expose :approval_rules_left, using: ApprovalRuleShort

        expose :has_approval_rules do |approval_state|
          approval_state.user_defined_rules.present?
        end

        expose :merge_request_approvers_available do |approval_state|
          approval_state.project.feature_available?(:merge_request_approvers)
        end

        expose :multiple_approval_rules_available do |approval_state|
          approval_state.project.multiple_approval_rules_available?
        end
      end

      class LdapGroup < Grape::Entity
        expose :cn
      end

      class GitlabLicense < Grape::Entity
        expose :id,
          :plan,
          :created_at,
          :starts_at,
          :expires_at,
          :historical_max,
          :maximum_user_count,
          :licensee,
          :add_ons

        expose :expired?, as: :expired

        expose :overage do |license, options|
          license.expired? ? license.overage_with_historical_max : license.overage(options[:current_active_users_count])
        end

        expose :user_limit do |license, options|
          license.restricted?(:active_user_count) ? license.restrictions[:active_user_count] : 0
        end
      end

      class GitlabLicenseWithActiveUsers < GitlabLicense
        expose :active_users do |license, options|
          ::User.active.count
        end
      end

      class GeoNode < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id
        expose :name
        expose :url
        expose :internal_url
        expose :primary?, as: :primary
        expose :enabled
        expose :current?, as: :current
        expose :files_max_capacity
        expose :repos_max_capacity
        expose :verification_max_capacity
        expose :container_repositories_max_capacity
        expose :sync_object_storage, if: ->(geo_node, _) { geo_node.secondary? }

        # Retained for backwards compatibility. Remove in API v5
        expose :clone_protocol do |_record, _options|
          'http'
        end

        expose :web_edit_url do |geo_node|
          ::Gitlab::Routing.url_helpers.edit_admin_geo_node_url(geo_node)
        end

        expose :web_geo_projects_url, if: ->(geo_node, _) { geo_node.secondary? } do |geo_node|
          geo_node.geo_projects_url
        end

        expose :_links do
          expose :self do |geo_node|
            expose_url api_v4_geo_nodes_path(id: geo_node.id)
          end

          expose :status do |geo_node|
            expose_url api_v4_geo_nodes_status_path(id: geo_node.id)
          end

          expose :repair do |geo_node|
            expose_url api_v4_geo_nodes_repair_path(id: geo_node.id)
          end
        end
      end

      class GeoNodeStatus < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers
        include ActionView::Helpers::NumberHelper

        expose :geo_node_id

        expose :healthy?, as: :healthy
        expose :health do |node|
          node.healthy? ? 'Healthy' : node.health
        end
        expose :health_status
        expose :missing_oauth_application

        expose :attachments_count
        expose :attachments_synced_count
        expose :attachments_failed_count
        expose :attachments_synced_missing_on_primary_count
        expose :attachments_synced_in_percentage do |node|
          number_to_percentage(node.attachments_synced_in_percentage, precision: 2)
        end

        expose :db_replication_lag_seconds

        expose :lfs_objects_count
        expose :lfs_objects_synced_count
        expose :lfs_objects_failed_count
        expose :lfs_objects_synced_missing_on_primary_count
        expose :lfs_objects_synced_in_percentage do |node|
          number_to_percentage(node.lfs_objects_synced_in_percentage, precision: 2)
        end

        expose :job_artifacts_count
        expose :job_artifacts_synced_count
        expose :job_artifacts_failed_count
        expose :job_artifacts_synced_missing_on_primary_count
        expose :job_artifacts_synced_in_percentage do |node|
          number_to_percentage(node.job_artifacts_synced_in_percentage, precision: 2)
        end

        expose :container_repositories_count
        expose :container_repositories_synced_count
        expose :container_repositories_failed_count
        expose :container_repositories_synced_in_percentage do |node|
          number_to_percentage(node.container_repositories_synced_in_percentage, precision: 2)
        end

        expose :design_repositories_count
        expose :design_repositories_synced_count
        expose :design_repositories_failed_count
        expose :design_repositories_synced_in_percentage do |node|
          number_to_percentage(node.design_repositories_synced_in_percentage, precision: 2)
        end

        expose :projects_count

        expose :repositories_failed_count
        expose :repositories_synced_count
        expose :repositories_synced_in_percentage do |node|
          number_to_percentage(node.repositories_synced_in_percentage, precision: 2)
        end

        expose :wikis_failed_count
        expose :wikis_synced_count
        expose :wikis_synced_in_percentage do |node|
          number_to_percentage(node.wikis_synced_in_percentage, precision: 2)
        end

        expose :repository_verification_enabled

        expose :repositories_checksummed_count
        expose :repositories_checksum_failed_count
        expose :repositories_checksummed_in_percentage do |node|
          number_to_percentage(node.repositories_checksummed_in_percentage, precision: 2)
        end

        expose :wikis_checksummed_count
        expose :wikis_checksum_failed_count
        expose :wikis_checksummed_in_percentage do |node|
          number_to_percentage(node.wikis_checksummed_in_percentage, precision: 2)
        end

        expose :repositories_verification_failed_count
        expose :repositories_verified_count
        expose :repositories_verified_in_percentage do |node|
          number_to_percentage(node.repositories_verified_in_percentage, precision: 2)
        end
        expose :repositories_checksum_mismatch_count

        expose :wikis_verification_failed_count
        expose :wikis_verified_count
        expose :wikis_verified_in_percentage do |node|
          number_to_percentage(node.wikis_verified_in_percentage, precision: 2)
        end
        expose :wikis_checksum_mismatch_count

        expose :repositories_retrying_verification_count
        expose :wikis_retrying_verification_count

        expose :replication_slots_count
        expose :replication_slots_used_count
        expose :replication_slots_used_in_percentage do |node|
          number_to_percentage(node.replication_slots_used_in_percentage, precision: 2)
        end
        expose :replication_slots_max_retained_wal_bytes

        expose :repositories_checked_count
        expose :repositories_checked_failed_count
        expose :repositories_checked_in_percentage do |node|
          number_to_percentage(node.repositories_checked_in_percentage, precision: 2)
        end

        expose :last_event_id
        expose :last_event_timestamp
        expose :cursor_last_event_id
        expose :cursor_last_event_timestamp

        expose :last_successful_status_check_timestamp

        expose :version
        expose :revision

        expose :selective_sync_type

        # Deprecated: remove in API v5. We use selective_sync_type instead now.
        expose :namespaces, using: ::API::Entities::NamespaceBasic

        expose :updated_at

        # We load GeoNodeStatus data in two ways:
        #
        # 1. Directly by asking a Geo node via an API call
        # 2. Via cached state in the database
        #
        # We don't yet cached the state of the shard information in the database, so if
        # we don't have this information omit from the serialization entirely.
        expose :storage_shards, using: StorageShardEntity, if: ->(status, options) do
          status.storage_shards.present?
        end

        expose :storage_shards_match?, as: :storage_shards_match

        expose :_links do
          expose :self do |geo_node_status|
            expose_url api_v4_geo_nodes_status_path(id: geo_node_status.geo_node_id)
          end

          expose :node do |geo_node_status|
            expose_url api_v4_geo_nodes_path(id: geo_node_status.geo_node_id)
          end
        end

        private

        def namespaces
          object.geo_node.namespaces
        end

        def missing_oauth_application
          object.geo_node.missing_oauth_application?
        end
      end

      class UnleashFeature < Grape::Entity
        expose :name
        expose :description, unless: ->(feature) { feature.description.nil? }
        expose :active, as: :enabled
        expose :strategies
      end

      class GitlabSubscription < Grape::Entity
        expose :plan do
          expose :plan_name, as: :code
          expose :plan_title, as: :name
          expose :trial
          expose :upgradable?, as: :upgradable
        end

        expose :usage do
          expose :seats, as: :seats_in_subscription
          expose :seats_in_use
          expose :max_seats_used
          expose :seats_owed
        end

        expose :billing do
          expose :start_date, as: :subscription_start_date
          expose :end_date, as: :subscription_end_date
          expose :trial_ends_on
        end
      end

      module ConanPackage
        class ConanPackageManifest < Grape::Entity
          expose :package_urls, merge: true
        end

        class ConanPackageSnapshot < Grape::Entity
          expose :package_snapshot, merge: true
        end

        class ConanRecipeManifest < Grape::Entity
          expose :recipe_urls, merge: true
        end

        class ConanRecipeSnapshot < Grape::Entity
          expose :recipe_snapshot, merge: true
        end

        class ConanUploadUrls < Grape::Entity
          expose :upload_urls, merge: true
        end
      end

      module Nuget
        class ServiceIndex < Grape::Entity
          expose :version
          expose :resources
        end
      end

      class NpmPackage < Grape::Entity
        expose :name
        expose :versions
        expose :dist_tags, as: 'dist-tags'
      end

      class Package < Grape::Entity
        expose :id
        expose :name
        expose :version
        expose :package_type
      end

      class PackageFile < Grape::Entity
        expose :id, :package_id, :created_at
        expose :file_name, :size
        expose :file_md5, :file_sha1
      end

      class ManagedLicense < Grape::Entity
        expose :id, :name
        expose :classification, as: :approval_status
      end

      class ProjectAlias < Grape::Entity
        expose :id, :project_id, :name
      end

      class Dependency < Grape::Entity
        class Vulnerability < Grape::Entity
          expose :name, :severity
        end

        expose :name, :version, :package_manager, :dependency_file_path
        expose :dependency_file_path do |dependency|
          dependency[:location][:path]
        end
        expose :vulnerabilities, using: Vulnerability, if: ->(_, opts) { can_read_vulnerabilities?(opts[:user], opts[:project]) }

        private

        def can_read_vulnerabilities?(user, project)
          Ability.allowed?(user, :read_project_security_dashboard, project)
        end
      end

      class FeatureFlag < Grape::Entity
        class Scope < Grape::Entity
          expose :id
          expose :active
          expose :environment_scope
          expose :strategies
          expose :created_at
          expose :updated_at
        end

        class DetailedScope < Scope
          expose :name
        end

        expose :name
        expose :description
        expose :created_at
        expose :updated_at
        expose :scopes, using: Scope
      end

      class Vulnerability < Grape::Entity
        expose :id
        expose :title
        expose :description

        expose :state
        expose :severity
        expose :confidence
        expose :report_type

        expose :project, using: ::API::Entities::ProjectIdentity

        expose :author_id
        expose :updated_by_id
        expose :last_edited_by_id
        expose :resolved_by_id
        expose :closed_by_id

        expose :start_date
        expose :due_date

        expose :created_at
        expose :updated_at
        expose :last_edited_at
        expose :resolved_at
        expose :closed_at
      end

      class VulnerabilityRelatedIssue < ::API::Entities::IssueBasic
        # vulnerability_link_* attributes come from joined Vulnerabilities::IssueLink record
        expose :vulnerability_link_id
        expose :vulnerability_link_type do |related_issue|
          ::Vulnerabilities::IssueLink.link_types.key(related_issue.vulnerability_link_type)
        end
      end
    end
  end
end
