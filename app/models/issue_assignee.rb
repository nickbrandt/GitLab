# frozen_string_literal: true

class IssueAssignee < ActiveRecord::Base
  prepend EE::IssueAssignee

  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id
end
