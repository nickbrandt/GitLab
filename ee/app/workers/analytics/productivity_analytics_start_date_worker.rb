# frozen_string_literal: true

# ProductivityAnalyticsStartDate worker is supposed to be executed once per instance
# after the first request to productivity analytics feature
class Analytics::ProductivityAnalyticsStartDateWorker
  include ApplicationWorker

  queue_namespace :analytics

  feature_category :code_analytics

  def perform
    settings = ApplicationSetting.current_without_cache

    return if settings['productivity_analytics_start_date']

    settings.update!(productivity_analytics_start_date: start_date)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def start_date
    without_statement_timeout do
      ::MergeRequest::Metrics.where('merged_at > ?', '2019-09-01')
        .where.not(commits_count: nil).order(merged_at: :asc)
        .limit(1).pluck(:merged_at).first || Time.now
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def without_statement_timeout
    ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
    yield
  ensure
    ActiveRecord::Base.connection.execute('RESET ALL')
  end
end
