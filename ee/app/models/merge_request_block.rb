# frozen_string_literal: true

class MergeRequestBlock < ApplicationRecord
  belongs_to :blocking_merge_request, class_name: 'MergeRequest'
  belongs_to :blocked_merge_request, class_name: 'MergeRequest'

  validates_presence_of :blocking_merge_request
  validates_presence_of :blocked_merge_request
  validates_uniqueness_of :blocked_merge_request, scope: :blocking_merge_request

  validate :check_block_constraints

  scope :with_blocking_mr_ids, -> (ids) do
    where(blocking_merge_request_id: ids).includes(:blocking_merge_request)
  end

  # Add a number of blocks at once. Pass a hash of blocking_id => blocked_id, or
  # an Array of [blocking_id, blocked_id] tuples
  def self.bulk_insert(pairs)
    now = Time.current

    rows = pairs.map do |blocking, blocked|
      {
        blocking_merge_request_id: blocking,
        blocked_merge_request_id: blocked,
        created_at: now,
        updated_at: now
      }
    end

    ::Gitlab::Database.bulk_insert(table_name, rows)
  end

  private

  def check_block_constraints
    return unless blocking_merge_request && blocked_merge_request

    errors.add(:base, _('This block is self-referential')) if
      blocking_merge_request == blocked_merge_request

    errors.add(:blocking_merge_request, _('cannot itself be blocked')) if
      blocking_merge_request.blocks_as_blockee.any?

    errors.add(:blocked_merge_request, _('cannot block others')) if
      blocked_merge_request.blocks_as_blocker.any?
  end
end
