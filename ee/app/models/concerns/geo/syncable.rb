# frozen_string_literal: true

module Geo::Syncable
  extend ActiveSupport::Concern

  included do
    scope :failed, -> { where(success: false).where.not(retry_count: nil) }
    scope :missing_on_primary, -> { where(missing_on_primary: true) }
    scope :pending, -> { where(success: false, retry_count: nil) }
    scope :retry_due, -> { where('retry_at is NULL OR retry_at < ?', Time.current) }
    scope :retryable, -> { failed.retry_due }
    scope :synced, -> { where(success: true) }
  end
end
