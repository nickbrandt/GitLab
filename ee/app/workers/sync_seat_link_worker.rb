# frozen_string_literal: true

class SyncSeatLinkWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :analysis

  # Retry for up to approximately 17 hours
  sidekiq_options retry: 12, dead: false

  def perform
    return unless should_sync_seats?

    SyncSeatLinkRequestWorker.perform_async(
      report_date.to_s,
      License.current.data,
      max_historical_user_count
    )
  end

  private

  # Only sync paid licenses from start date until 14 days after expiration
  def should_sync_seats?
    License.current &&
    !License.current.trial? &&
    report_date.between?(License.current.starts_at, License.current.expires_at + 14.days)
  end

  def max_historical_user_count
    HistoricalData.max_historical_user_count(
      from: License.current.starts_at,
      to: report_date
    )
  end

  def report_date
    @report_date ||= Time.now.utc.yesterday.to_date
  end
end
