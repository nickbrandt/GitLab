# frozen_string_literal: true

module ApprovalRuleLike
  extend ActiveSupport::Concern

  DEFAULT_NAME = 'Default'
  DEFAULT_NAME_FOR_LICENSE_REPORT = 'License-Check'
  DEFAULT_NAME_FOR_SECURITY_REPORT = 'Vulnerability-Check'
  REPORT_TYPES_BY_DEFAULT_NAME = {
    DEFAULT_NAME_FOR_LICENSE_REPORT => :license_scanning,
    DEFAULT_NAME_FOR_SECURITY_REPORT => :security
  }.freeze
  APPROVALS_REQUIRED_MAX = 100
  ALL_MEMBERS = 'All Members'

  included do
    has_and_belongs_to_many :users,
      after_add: :audit_add, after_remove: :audit_remove
    has_and_belongs_to_many :groups,
      class_name: 'Group', join_table: "#{self.table_name}_groups",
      after_add: :audit_add, after_remove: :audit_remove
    has_many :group_users, -> { distinct }, through: :groups, source: :users

    validates :name, presence: true
    validates :approvals_required, numericality: { less_than_or_equal_to: APPROVALS_REQUIRED_MAX, greater_than_or_equal_to: 0 }

    scope :with_users, -> { preload(:users, :group_users) }
    scope :regular_or_any_approver, -> { where(rule_type: [:regular, :any_approver]) }
  end

  def audit_add
    raise NotImplementedError
  end

  def audit_remove
    raise NotImplementedError
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

  def any_approver?
    raise NotImplementedError
  end

  def user_defined?
    regular? || any_approver?
  end

  def overridden?
    return false unless source_rule.present?

    source_rule.name != name ||
      source_rule.approvals_required != approvals_required ||
      different_users_or_groups?
  end

  private

  def different_users_or_groups?
    results = ApplicationRecord.connection.execute(<<-SQL.squish)
      SELECT different_elements
      FROM (
        (SELECT 1 AS different_elements
        FROM "#{self.class.table_name}_groups"
        WHERE "#{self.class.table_name}_groups"."#{self.class.underscore}_id" = #{self.id}
          AND "#{self.class.table_name}_groups"."group_id" NOT IN
            (SELECT group_id
              FROM "#{source_rule.class.table_name}_groups"
              WHERE "#{source_rule.class.table_name}_groups"."#{source_rule.class.underscore}_id" = #{source_rule.id})
        LIMIT 1)
      UNION
        (SELECT 1 AS different_elements
        FROM "#{self.class.table_name}_users"
        WHERE "#{self.class.table_name}_users"."#{self.class.underscore}_id" = #{self.id}
          AND "#{self.class.table_name}_users"."user_id" NOT IN
            (SELECT user_id
              FROM "#{source_rule.class.table_name}_users"
              WHERE "#{source_rule.class.table_name}_users"."#{source_rule.class.underscore}_id" = #{source_rule.id})
        LIMIT 1)) AS tmp_table
    SQL

    results.first.present?
  end

  # def old_different_users_or_groups?
  #   prepared_column = 'different_elements'
  #   prepared_groups, prepared_users = [different_groups, different_users].map { |rel| rel.limit(1).select("1 as #{prepared_column}") }
  #   union = Gitlab::SQL::Union.new([prepared_groups, prepared_users]) # rubocop: disable Gitlab/Union

  #   ActiveRecord::Base.connection.execute("Select #{prepared_column} from (#{union.to_sql}) AS tmp_table").first.present?
  # end

  # def different_groups
  #   groups.where.not(id: source_rule.groups.select(:id))
  # end

  # def different_users
  #   users.where.not(id: source_rule.users.select(:id))
  # end
end




