# frozen_string_literal: true

class IssueLink < ApplicationRecord
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

  private

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end
end
