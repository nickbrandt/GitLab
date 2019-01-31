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
    project_rule_ids = ApprovalMergeRequestRule
      .joins(:approval_project_rule)
      .where('approval_merge_request_rules.approvals_required = 0 AND approval_project_rules.approvals_required > 0')
      .pluck('approval_project_rules.id')

    ApprovalProjectRule.where(id: project_rule_ids).find_each do |project_rule|
      # rubocop:disable GitlabSecurity/SqlInjection
      # Pluck as MySQL prohibits subquery that references the table being updated
      mr_rule_ids = ApprovalMergeRequestRule
        .joins(:approval_merge_request_rule_source)
        .where("approval_merge_request_rules.approvals_required = 0 AND approval_merge_request_rule_sources.approval_project_rule_id = #{project_rule.id}")
        .pluck('approval_merge_request_rules.id')
      # rubocop:enable GitlabSecurity/SqlInjection

      ApprovalMergeRequestRule.where(id: mr_rule_ids).update_all(approvals_required: project_rule.approvals_required)
    end
  end

  def down
  end
end
