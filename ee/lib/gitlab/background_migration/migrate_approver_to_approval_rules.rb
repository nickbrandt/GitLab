# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A Project/MergeRequest level migration, aiming to convert existing data
    # (from approvers, approver_groups and approvals tables)
    # to new rule based schema.
    class MigrateApproverToApprovalRules
      include Gitlab::Utils::StrongMemoize

      class Approver < ActiveRecord::Base
        self.table_name = 'approvers'
      end

      class ApproverGroup < ActiveRecord::Base
        self.table_name = 'approver_groups'
      end

      class ApprovalMergeRequestRule < ApplicationRecord
        self.table_name = 'approval_merge_request_rules'

        include Gitlab::Utils::StrongMemoize

        belongs_to :merge_request
        scope :code_owner, -> { where(code_owner: true) }
        scope :regular, -> { where(code_owner: false) } # Non code owner rule

        has_and_belongs_to_many :users
        has_and_belongs_to_many :groups, class_name: 'Group', join_table: :approval_merge_request_rules_groups
        has_and_belongs_to_many :approvals # This is only populated after merge request is merged
        has_many :approved_approvers, through: :approvals, source: :user
        has_one :approval_merge_request_rule_source
        has_one :approval_project_rule, through: :approval_merge_request_rule_source

        def project
          merge_request.target_project
        end

        # Users who are eligible to approve, including specified group members.
        # Excludes the author if 'self-approval' isn't explicitly
        # enabled on project settings.
        # @return [Array<User>]
        def approvers
          strong_memoize(:approvers) do
            scope = User.from_union(
              [
                users,
                User.joins(:group_members).where(members: { source_id: groups })
              ]
            )

            if merge_request.author && !project.merge_requests_author_approval?
              scope = scope.where.not(id: merge_request.author)
            end

            scope
          end
        end

        def sync_approvals
          # Before being merged, approvals are dynamically calculated instead of being persisted in the db.
          return unless merge_request.merged?

          self.approvals = merge_request.approvals.where(user_id: approvers.map(&:id))
        end
      end

      class ApprovalMergeRequestRuleSource < ApplicationRecord
        self.table_name = 'approval_merge_request_rule_sources'
        belongs_to :approval_merge_request_rule
        belongs_to :approval_project_rule
      end

      class ApprovalProjectRule < ActiveRecord::Base
        self.table_name = 'approval_project_rules'

        belongs_to :project
        has_and_belongs_to_many :users
        has_and_belongs_to_many :groups, class_name: 'Group', join_table: :approval_project_rules_groups

        scope :regular, -> { all }
      end

      class MergeRequest < ActiveRecord::Base
        self.table_name = 'merge_requests'
        include ::EachBatch

        belongs_to :target_project, class_name: "Project"
        belongs_to :author, class_name: "User"
        has_many :approval_rules, class_name: 'ApprovalMergeRequestRule'
        has_many :approvals

        def approvers
          Approver.where(target_type: 'MergeRequest', target_id: id)
        end

        def approver_groups
          ApproverGroup.where(target_type: 'MergeRequest', target_id: id)
        end

        def merged?
          state == 'merged'
        end

        def sync_code_owners_with_approvers
          ::MergeRequest.find(id).sync_code_owners_with_approvers
        end

        def finalize_approvals
          return unless merged?

          copy_project_approval_rules unless approval_rules.regular.exists?

          approval_rules.reload.each(&:sync_approvals)
        end

        private

        def copy_project_approval_rules
          target_project.approval_rules.each do |project_rule|
            rule = approval_rules.create!(project_rule.attributes.slice('approvals_required', 'name'))
            rule.users = project_rule.users
            rule.groups = project_rule.groups
          end
        end
      end

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        has_many :merge_requests, foreign_key: 'target_project_id', inverse_of: :target_project
        has_many :approval_rules, class_name: 'ApprovalProjectRule'

        def approvers
          Approver.where(target_type: 'Project', target_id: id)
        end

        def approver_groups
          ApproverGroup.where(target_type: 'Project', target_id: id)
        end
      end

      class User < ActiveRecord::Base
        include FromUnion

        self.table_name = 'users'

        has_many :group_members, -> { where(requested_at: nil) }, source: 'GroupMember'
      end

      ALLOWED_TARGET_TYPES = %w{MergeRequest Project}.freeze

      # @param target_type [String] class of target, either 'MergeRequest' or 'Project'
      # @param target_id [Integer] id of target
      def perform(target_type, target_id)
        @target_type = target_type
        @target_id = target_id

        raise "Incorrect target_type #{target_type}" unless ALLOWED_TARGET_TYPES.include?(@target_type)

        case target
        when MergeRequest
          handle_merge_request
        when Project
          handle_project
        end
      end

      private

      def handle_merge_request
        ActiveRecord::Base.transaction do
          if rule = sync_rule
            rule.approval_project_rule = target.target_project.approval_rules.regular.first
          end

          target.sync_code_owners_with_approvers

          target.finalize_approvals if target.merged?
        end
      end

      def handle_project
        ActiveRecord::Base.transaction do
          sync_rule
        end

        schedule_to_migrate_merge_requests(target)
      end

      def sync_rule
        unless approvers_exists?
          target.approval_rules.regular.delete_all
          return
        end

        rule = find_or_create_rule
        rule.user_ids = target.approvers.pluck(:user_id)
        rule.group_ids = target.approver_groups.pluck(:group_id)
        rule
      end

      def schedule_to_migrate_merge_requests(project)
        jobs = []
        project.merge_requests.each_batch do |scope, _|
          jobs << ['MigrateApproverToApprovalRulesInBatch', ['MergeRequest', scope.pluck(:id)]]
        end
        BackgroundMigrationWorker.bulk_perform_async(jobs)
      end

      def target
        strong_memoize(:target) do
          case @target_type
          when 'MergeRequest'
            MergeRequest.find_by(id: @target_id)
          when 'Project'
            Project.find_by(id: @target_id)
          end
        end
      end

      def find_or_create_rule
        rule = target.approval_rules.regular.find_or_initialize_by(name: 'Default')

        unless rule.persisted?
          rule.approvals_required = target.approvals_before_merge || 0
          rule.save!
        end

        rule
      end

      def approvers_exists?
        target.approvers.to_a.any? || target.approver_groups.to_a.any?
      end
    end
  end
end
