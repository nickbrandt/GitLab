# frozen_string_literal: true

# Analytics worker to perform analytics specific data updates like backfill tasks
class AnalyticsWorker
  include ApplicationWorker
  include HealthcheckAwareWorker

  def database_unhealthy_counter
    Gitlab::Metrics.counter(
      :analytics_task_database_health_reschedules,
      'The number of times an analytics task is rescheduled because the database is unhealthy.'
    )
  end

  private

  def perform_task(class_name, arguments)
    job_class(class_name).new.perform(*arguments)
  end

  def job_class(name)
    name.constantize
  end
end
