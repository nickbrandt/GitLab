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
  end

  def up
    ApprovalProjectRule.find_each do |project_rule|
      # rubocop:disable GitlabSecurity/SqlInjection
      target_mr_rules = ApprovalMergeRequestRule
        .joins(:approval_project_rule)
        .where("approval_merge_request_rules.approvals_required = 0 AND approval_project_rules.id = #{project_rule.id} AND approval_project_rules.approvals_required > 0")
        .select('approval_merge_request_rules.id')
      # rubocop:enable GitlabSecurity/SqlInjection

      # MySQL prohibits subquery that references the table being updated
      target_mr_rules = target_mr_rules.pluck(:id)

      ApprovalMergeRequestRule.where(id: target_mr_rules).update_all(approvals_required: project_rule.approvals_required)
    end
  end

  def down
  end
end
