# frozen_string_literal: true

# Fix data for https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/9143
# Check MR rules which has 0 and update to project approval rate.
class CorrectApprovalsRequired < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class ApprovalMergeRequestRule < ActiveRecord::Base
    self.table_name = 'approval_merge_request_rules'
    has_one :approval_merge_request_rule_source
    has_one :approval_project_rule, through: :approval_merge_request_rule_source
  end

  class ApprovalProjectRule < ActiveRecord::Base
    self.table_name = 'approval_project_rules'

    has_many :approval_merge_request_rule_source
    has_many :approval_merge_request_rules, through: :approval_merge_request_rule_source
  end

  def up
    ApprovalProjectRule
      .joins(:approval_merge_request_rules)
      .where('approval_merge_request_rules.approvals_required = 0 AND approval_project_rules.approvals_required > 0')
      .find_each do |project_rule|
      # Pluck as MySQL prohibits subquery that references the table being updated
      mr_rule_ids = ApprovalMergeRequestRule
        .joins(:approval_merge_request_rule_source)
        .where("approval_merge_request_rules.approvals_required = 0 AND approval_merge_request_rule_sources.approval_project_rule_id = #{project_rule.id}")
        .pluck('approval_merge_request_rules.id')

      ApprovalMergeRequestRule.where(id: mr_rule_ids).update_all(approvals_required: project_rule.approvals_required)
    end
  end

  def down
  end
end
