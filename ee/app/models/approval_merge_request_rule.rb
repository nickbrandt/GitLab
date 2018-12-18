# frozen_string_literal: true

class ApprovalMergeRequestRule < ApplicationRecord
  include ApprovalRuleLike

  scope :regular, -> { where(code_owner: false) }
  scope :code_owner, -> { where(code_owner: true) } # special code owner rules, updated internally when code changes

  belongs_to :merge_request

  has_and_belongs_to_many :approvals # This is only populated after merge request is merged
  has_many :approved_approvers, through: :approvals, source: :user
  has_one :approval_merge_request_rule_source
  has_one :approval_project_rule, through: :approval_merge_request_rule_source

  def project
    merge_request.target_project
  end

  # Users who are eligible to approve, including specified group members.
  # Excludes the author if 'self-approval' isn't explicitly
  # enabled on project settings.
  # @return [Array<User>]
  def approvers
    scope = super

    if merge_request.author && !project.merge_requests_author_approval?
      scope = scope.where.not(id: merge_request.author)
    end

    scope
  end

  def sync_approvals
    # Before being merged, approvals are dynamically calculated instead of being persisted.
    return unless merge_request.merged?

    self.approvals = merge_request.approvals.where(user_id: approvers.map(&:id))
  end
end
