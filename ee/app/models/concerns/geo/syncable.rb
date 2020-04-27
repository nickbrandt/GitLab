# frozen_string_literal: true

module Geo::Syncable
  extend ActiveSupport::Concern

  included do
    scope :pending_delete, -> { where(pending_delete: true) }
    scope :without_deleted, -> { where(pending_delete: false) }
    scope :failed, -> { where(success: false).without_deleted }
    scope :synced, -> { where(success: true, pending_delete: false).without_deleted }
    scope :never, -> { where(success: false, retry_count: nil).without_deleted }
    scope :retry_due, -> { where('retry_at is NULL OR retry_at < ?', Time.now).without_deleted }
    scope :missing_on_primary, -> { where(missing_on_primary: true).without_deleted }
  end
end
