# frozen_string_literal: true

class MergeRequestApprovalSetting < ApplicationRecord
  belongs_to :namespace, inverse_of: :merge_request_approval_settings

  default_value_for :allow_author_approval, true

  validates :namespace, presence: true
  validates :namespace_id, uniqueness: true, allow_nil: true
  validates :allow_author_approval, inclusion: { in: [true, false], message: 'must be a boolean value' }

  scope :find_or_initialize_by_namespace, ->(namespace) {
    find_or_initialize_by(namespace: namespace)
  }
end
