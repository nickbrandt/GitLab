# frozen_string_literal: true

class BackgroundMigrationWorker
  include ApplicationWorker
  include HealthcheckAwareWorker

  def database_unhealthy_counter
    Gitlab::Metrics.counter(
      :background_migration_database_health_reschedules,
      'The number of times a background migration is rescheduled because the database is unhealthy.'
    )
  end

  private

  def perform_task(class_name, arguments)
    Gitlab::BackgroundMigration.perform(class_name, arguments)
  end
end
