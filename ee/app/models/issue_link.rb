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

  class << self
    def inverse_link_type(type)
      case type
      when TYPE_BLOCKS
        TYPE_IS_BLOCKED_BY
      when TYPE_IS_BLOCKED_BY
        TYPE_BLOCKS
      else
        type
      end
    end

    def blocked_issue_ids(issue_ids)
      blocked_and_blocking_issues_union(issue_ids).pluck(:blocked_issue_id)
    end

    def blocking_issue_ids_for(issue)
      blocked_and_blocking_issues_union(issue.id).pluck(:blocking_issue_id)
    end
  end

  private

  class << self
    def blocked_and_blocking_issues_union(issue_ids)
      from_union([
        blocked_or_blocking_issues(issue_ids, IssueLink::TYPE_BLOCKS),
        blocked_or_blocking_issues(issue_ids, IssueLink::TYPE_IS_BLOCKED_BY)
      ])
    end

    def blocked_or_blocking_issues(issue_ids, link_type)
      if link_type == IssueLink::TYPE_BLOCKS
        blocked_key = :target_id
        blocking_key = :source_id
      else
        blocked_key = :source_id
        blocking_key = :target_id
      end

      select("#{blocked_key} as blocked_issue_id, #{blocking_key} as blocking_issue_id")
        .where(link_type: link_type).where(blocked_key => issue_ids)
        .joins("INNER JOIN issues ON issues.id = issue_links.#{blocking_key}")
        .where('issues.state_id' => Issuable::STATE_ID_MAP[:opened])
    end

    def blocking_issues_for_collection(issues_ids)
      from_union([
        select('COUNT(*), issue_links.source_id AS blocking_issue_id')
          .joins(:target)
          .where(issues: { state_id: Issue.available_states[:opened] })
          .where(link_type: TYPE_BLOCKS)
          .where(source_id: issues_ids)
          .group(:blocking_issue_id),
        select('COUNT(*), issue_links.target_id AS blocking_issue_id')
          .joins(:source)
          .where(issues: { state_id: Issue.available_states[:opened] })
          .where(link_type: TYPE_IS_BLOCKED_BY)
          .where(target_id: issues_ids)
          .group(:blocking_issue_id)
      ], remove_duplicates: false).select('blocking_issue_id, SUM(count) AS count').group('blocking_issue_id')
    end

    def blocked_issues_for_collection(issues_ids)
      from_union([
        select('COUNT(*), issue_links.source_id AS blocked_issue_id')
          .joins(:target)
          .where(issues: { state_id: Issue.available_states[:opened] })
          .where(link_type: TYPE_IS_BLOCKED_BY)
          .where(source_id: issues_ids)
          .group(:blocked_issue_id),
        select('COUNT(*), issue_links.target_id AS blocked_issue_id')
          .joins(:source)
          .where(issues: { state_id: Issue.available_states[:opened] })
          .where(link_type: TYPE_BLOCKS)
          .where(target_id: issues_ids)
          .group(:blocked_issue_id)
      ], remove_duplicates: false).select('blocked_issue_id, SUM(count) AS count').group('blocked_issue_id')
    end
  end

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end
end
