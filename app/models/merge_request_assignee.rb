# frozen_string_literal: true

class MergeRequestAssignee < ApplicationRecord
  belongs_to :merge_request
  belongs_to :assignee, inverse_of: :merge_request_assignees, class_name: "User", foreign_key: :user_id
end
