# frozen_string_literal: true

require 'sidekiq/api'

Sidekiq::Worker.extend ActiveSupport::Concern

module HealthcheckAwareWorker
  extend ActiveSupport::Concern

  class_methods do
    # The minimum amount of time between processing two jobs of the same
    # class.
    #
    # This interval is set to 2 or 5 minutes so autovacuuming and other
    # maintenance related tasks have plenty of time to clean up after a task
    # has been performed.
    def minimum_interval
      2.minutes.to_i
    end
  end

  # Performs resource heavy task.
  #
  # See Gitlab::BackgroundMigration.perform for more information.
  #
  # class_name - The class name of the task to run.
  # arguments - The arguments to pass to the task.
  def perform(class_name, arguments = [])
    should_perform, ttl = perform_and_ttl(class_name)

    if should_perform
      perform_task(class_name, arguments)
    else
      # If the lease could not be obtained this means either another process is
      # running a task of this class or we ran one recently. In this case
      # we'll reschedule the job in such a way that it is picked up again around
      # the time the lease expires.
      self.class
        .perform_in(ttl || self.class.minimum_interval, class_name, arguments)
    end
  end

  def perform_and_ttl(class_name)
    if always_perform?
      # In test environments `perform_in` will run right away. This can then
      # lead to stack level errors in the above `#perform`. To work around this
      # we'll just perform the task right away in the test environment.
      [true, nil]
    else
      lease = lease_for(class_name)
      perform = !!lease.try_obtain

      # If we managed to acquire the lease but the DB is not healthy, then we
      # want to simply reschedule our job and try again _after_ the lease
      # expires.
      if perform && !healthy_database?
        database_unhealthy_counter.increment

        perform = false
      end

      [perform, lease.ttl]
    end
  end

  def lease_for(class_name)
    Gitlab::ExclusiveLease
      .new(lease_key_for(class_name), timeout: self.class.minimum_interval)
  end

  def lease_key_for(class_name)
    "#{self.class.name}:#{class_name}"
  end

  def always_perform?
    Rails.env.test?
  end

  # Returns true if the database is healthy enough to allow the task to be
  # performed.
  def healthy_database?
    !Postgresql::ReplicationSlot.lag_too_great?
  end

  def database_unhealthy_counter
    raise NotImplementedError # Must be implemented in child classes. Check BackgroundMigrationWorker for example.
  end

  private

  def perform_task(class_name, arguments)
    raise NotImplementedError # Must be implemented in child classes
  end
end
