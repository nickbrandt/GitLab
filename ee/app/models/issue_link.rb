# frozen_string_literal: true

class IssueLink < ApplicationRecord
  include FromUnion

  belongs_to :source, class_name: 'Issue'
  belongs_to :target, class_name: 'Issue'

  validates :source, presence: true
  validates :target, presence: true
  validates :source, uniqueness: { scope: :target_id, message: 'is already related' }
  validate :check_self_relation

  scope :for_source_issue, ->(issue) { where(source_id: issue.id) }
  scope :for_target_issue, ->(issue) { where(target_id: issue.id) }

  TYPE_RELATES_TO = 'relates_to'
  TYPE_BLOCKS = 'blocks'
  TYPE_IS_BLOCKED_BY = 'is_blocked_by'

  enum link_type: { TYPE_RELATES_TO => 0, TYPE_BLOCKS => 1, TYPE_IS_BLOCKED_BY => 2 }

  def self.inverse_link_type(type)
    case type
    when TYPE_BLOCKS
      TYPE_IS_BLOCKED_BY
    when TYPE_IS_BLOCKED_BY
      TYPE_BLOCKS
    else
      type
    end
  end

  def self.blocked_issue_ids(issue_ids)
    from_union([
      IssueLink.select('target_id as issue_id').where(link_type: IssueLink::TYPE_BLOCKS).where(target_id: issue_ids),
      IssueLink.select('source_id as issue_id').where(link_type: IssueLink::TYPE_IS_BLOCKED_BY).where(source_id: issue_ids)
    ]).pluck(:issue_id)
  end

  private

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end
end
