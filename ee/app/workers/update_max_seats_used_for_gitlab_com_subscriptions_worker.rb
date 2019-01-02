# frozen_string_literal: true

class UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return unless ::Gitlab::Database.postgresql?
    return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

    GitlabSubscription.with_a_paid_hosted_plan.find_in_batches(batch_size: 100) do |subscriptions|
      tuples = []

      subscriptions.each do |subscription|
        seats_in_use = subscription.seats_in_use

        next if subscription.max_seats_used >= seats_in_use

        tuples << [subscription.id, seats_in_use]
      end

      if tuples.present?
        GitlabSubscription.connection.execute <<-EOF
          UPDATE gitlab_subscriptions AS s SET max_seats_used = v.max_seats_used
          FROM (VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}) AS v(id, max_seats_used)
          WHERE s.id = v.id
        EOF
      end
    end
  end
end
