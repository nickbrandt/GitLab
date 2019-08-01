# frozen_string_literal: true

namespace :gitlab do
  namespace :productivity_analytics do
    desc 'Recalculates productivity analytics for all MRs merged after MERGED_AT_AFTER date.'
    task recalc: :environment do
      merged_at_after = ENV['MERGED_AT_AFTER'] ? DateTime.parse(ENV['MERGED_AT_AFTER']) : 6.months.ago

      migration_name = 'Analytics::ProductivityRecalculateService'

      if ENV['PERFORM_ASYNC']
        AnalyticsWorker.perform_async(migration_name, [merged_at_after])
        puts 'Data backfill is scheduled to be performed asynchronously'
      else
        AnalyticsWorker.new.perform(migration_name, [merged_at_after])
      end
    end
  end
end
