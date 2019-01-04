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
      end

      class ApproverGroup < ActiveRecord::Base
        self.table_name = 'approver_groups'
      end

      class ApprovalMergeRequestRule < ActiveRecord::Base
        self.table_name = 'approval_merge_request_rules'

        include Gitlab::Utils::StrongMemoize

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

        def approvers
          Approver.where(target_type: 'MergeRequest', target_id: id)
        end

        def approver_groups
          ApproverGroup.where(target_type: 'MergeRequest', target_id: id)
        end

        def sync_code_owners_with_approvers
          ::MergeRequest.find(id).sync_code_owners_with_approvers
        end
      end

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        has_many :approval_rules, class_name: 'ApprovalProjectRule'

        def approvers
          Approver.where(target_type: 'Project', target_id: id)
        end

        def approver_groups
          ApproverGroup.where(target_type: 'Project', target_id: id)
        end
      end

      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      ALLOWED_TARGET_TYPES = %w{MergeRequest Project}.freeze

      # @param target_type [String] class of target, either 'MergeRequest' or 'Project'
      # @param target_id [Integer] id of target
      def perform(target_type, target_id)
        @target_type = target_type
        @target_id = target_id

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

        target.sync_code_owners_with_approvers
      end

      def handle_project
        sync_rule
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
