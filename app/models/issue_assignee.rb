# frozen_string_literal: true

class IssueAssignee < ApplicationRecord
  belongs_to :issue
  belongs_to :assignee, inverse_of: :issue_assignees, class_name: "User", foreign_key: :user_id
end

IssueAssignee.prepend_if_ee('EE::IssueAssignee')
