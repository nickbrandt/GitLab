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
      blocked_issues(issue_ids, IssueLink::TYPE_BLOCKS),
      blocked_issues(issue_ids, IssueLink::TYPE_IS_BLOCKED_BY)
    ]).pluck(:issue_id)
  end

  private

  def self.blocked_issues(issue_ids, link_type)
    if link_type == IssueLink::TYPE_BLOCKS
      blocked_key = :target_id
      blocking_key = :source_id
    else
      blocked_key = :source_id
      blocking_key = :target_id
    end

    select("#{blocked_key} as issue_id")
      .where(link_type: link_type).where(blocked_key => issue_ids)
      .joins("INNER JOIN issues ON issues.id = issue_links.#{blocking_key}")
      .where('issues.state_id' => Issuable::STATE_ID_MAP[:opened])
  end

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end
end
