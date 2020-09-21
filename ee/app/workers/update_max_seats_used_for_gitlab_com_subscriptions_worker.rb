# frozen_string_literal: true

class UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :license_compliance
  worker_resource_boundary :cpu

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return if ::Gitlab::Database.read_only?
    return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

    GitlabSubscription.with_a_paid_hosted_plan.preload_for_refresh_seat.find_in_batches(batch_size: 100) do |subscriptions|
      tuples = []

      subscriptions.each do |subscription|
        unless subscription.namespace
          track_error(subscription)
          next
        end

        subscription.refresh_seat_attributes!

        tuples << {
          id: subscription.id,
          max_seats_used: subscription.max_seats_used,
          seats_in_use: subscription.seats_in_use,
          seats_owed: subscription.seats_owed
        }
      end

      GitlabSubscription.upsert_all(tuples, returning: false, unique_by: :id) if tuples.present?
    end
  end

  private

  def track_error(subscription)
    Gitlab::ErrorTracking.track_exception(
      StandardError.new('Namespace absent'),
      gitlab_subscription_id: subscription.id,
      namespace_id: subscription.namespace_id
    )
  end
end
