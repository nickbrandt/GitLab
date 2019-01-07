# frozen_string_literal: true

# Allow MR rule to lookup its project rule source
class ApprovalMergeRequestRuleSource < ApplicationRecord
  belongs_to :approval_merge_request_rule
  belongs_to :approval_project_rule
end
