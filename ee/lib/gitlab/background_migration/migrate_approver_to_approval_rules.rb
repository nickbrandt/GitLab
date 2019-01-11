# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A Project/MergeRequest level migration, aiming to convert existing data
    # (from approvers, approver_groups tables)
    # to new rule based schema.
    class MigrateApproverToApprovalRules
      include Gitlab::Utils::StrongMemoize

      class Approver < ActiveRecord::Base
        self.table_name = 'approvers'
        belongs_to :user
      end

      class ApproverGroup < ActiveRecord::Base
        self.table_name = 'approver_groups'
        belongs_to :group
      end

      class ApprovalMergeRequestRule < ActiveRecord::Base
        self.table_name = 'approval_merge_request_rules'

        belongs_to :merge_request
        scope :code_owner, -> { where(code_owner: true) }
        scope :regular, -> { where(code_owner: false) } # Non code owner rule

        has_and_belongs_to_many :users
        has_and_belongs_to_many :groups, class_name: 'Group', join_table: :approval_merge_request_rules_groups
        has_one :approval_merge_request_rule_source
        has_one :approval_project_rule, through: :approval_merge_request_rule_source

        def project
          merge_request.target_project
        end
      end

      class ApprovalMergeRequestRuleSource < ActiveRecord::Base
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

        belongs_to :target_project, class_name: "Project"
        has_many :approval_rules, class_name: 'ApprovalMergeRequestRule'

        def approver_ids
          @approver_ids ||= Approver.where(target_type: 'MergeRequest', target_id: id).joins(:user).pluck('distinct user_id')
        end

        def approver_group_ids
          @approver_group_ids ||= ApproverGroup.where(target_type: 'MergeRequest', target_id: id).joins(:group).pluck('distinct group_id')
        end

        def sync_code_owners_with_approvers
          return if state == 'merged' || state == 'closed'

          Gitlab::GitalyClient.allow_n_plus_1_calls do
            ::MergeRequest.find(id).sync_code_owners_with_approvers
          end
        end
      end

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        has_many :approval_rules, class_name: 'ApprovalProjectRule'

        def approver_ids
          @approver_ids ||= Approver.where(target_type: 'Project', target_id: id).joins(:user).pluck('distinct user_id')
        end

        def approver_group_ids
          @approver_group_ids ||= ApproverGroup.where(target_type: 'Project', target_id: id).joins(:group).pluck('distinct group_id')
        end
      end

      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      ALLOWED_TARGET_TYPES = %w{MergeRequest Project}.freeze

      # @param target_type [String] class of target, either 'MergeRequest' or 'Project'
      # @param target_id [Integer] id of target
      def perform(target_type, target_id, sync_code_owner_rule: true)
        @target_type = target_type
        @target_id = target_id
        @sync_code_owner_rule = sync_code_owner_rule

        raise "Incorrect target_type #{target_type}" unless ALLOWED_TARGET_TYPES.include?(@target_type)

        ActiveRecord::Base.transaction do
          case target
          when MergeRequest
            handle_merge_request
          when Project
            handle_project
          end
        end
      end

      private

      def handle_merge_request
        if rule = sync_rule
          rule.approval_project_rule = target.target_project.approval_rules.regular.first
        end

        target.sync_code_owners_with_approvers if @sync_code_owner_rule
      end

      def handle_project
        sync_rule
      end

      def sync_rule
        unless approvers_exists?
          target.approval_rules.regular.delete_all
          return
        end

        rule = first_or_initialize
        rule.update(user_ids: target.approver_ids, group_ids: target.approver_group_ids)
        rule
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

      def first_or_initialize
        rule = target.approval_rules.regular.first_or_initialize

        unless rule.persisted?
          rule.name ||= ApprovalRuleLike::DEFAULT_NAME
          rule.approvals_required = target.approvals_before_merge || 0
          rule.save!
        end

        rule
      end

      def approvers_exists?
        target.approver_ids.any? || target.approver_group_ids.any?
      end
    end
  end
end
