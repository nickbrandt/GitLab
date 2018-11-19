# frozen_string_literal: true

class Approval < ActiveRecord::Base
  belongs_to :user
  belongs_to :merge_request
  has_and_belongs_to_many :approval_rules, class_name: 'ApprovalMergeRequestRule', join_table: :approval_merge_request_rules_approvals

  validates :merge_request_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: [:merge_request_id] }
end
