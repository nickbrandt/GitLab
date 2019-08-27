# frozen_string_literal: true

module ApprovalRuleLike
  extend ActiveSupport::Concern

  DEFAULT_NAME = 'Default'
  DEFAULT_NAME_FOR_SECURITY_REPORT = 'Vulnerability-Check'
  APPROVALS_REQUIRED_MAX = 100

  included do
    has_and_belongs_to_many :users
    has_and_belongs_to_many :groups, class_name: 'Group', join_table: "#{self.table_name}_groups"
    has_many :group_users, -> { distinct }, through: :groups, source: :users

    validates :name, presence: true
    validates :approvals_required, numericality: { less_than_or_equal_to: APPROVALS_REQUIRED_MAX, greater_than_or_equal_to: 0 }

    scope :with_users, -> { preload(:users, :group_users) }
  end

  # Users who are eligible to approve, including specified group members.
  # @return [Array<User>]
  def approvers
    @approvers ||= if users.loaded? && group_users.loaded?
                     users | group_users
                   else
                     User.from_union([users, group_users])
                   end
  end

  def code_owner?
    raise NotImplementedError
  end

  def regular?
    raise NotImplementedError
  end

  def report_approver?
    raise NotImplementedError
  end
end
