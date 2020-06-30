# frozen_string_literal: true

class LabelLink < ApplicationRecord
  include BulkInsertSafe
  include Importable

  belongs_to :target, polymorphic: true, inverse_of: :label_links # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :label

  validates :target, presence: true, unless: :importing?
  validates :label, presence: true, unless: :importing?

  scope :preloaded, -> { preload(:label) }

  scope :for_targets, ->(type:, scope:) { where(target_type: type, target_id: scope) }
  scope :for_merge_requests, ->(merge_request_scope) { for_targets(type: MergeRequest, scope: merge_request_scope) }
end
