# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationRunner
        def initialize(migration_wrapper = BatchedMigrationWrapper.new)
          @migration_wrapper = migration_wrapper
        end

        # Runs the next batched_job for a batched_background_migration.
        #
        # The batch bounds of the next job are calculated at runtime, based on the migration
        # configuration and the bounds of the most recently created batched_job. Updating the
        # migration configuration will cause future jobs to use the updated batch sizes.
        #
        # The job instance will automatically receive a set of arguments based on the migration
        # configuration. For more details, see the BatchedMigrationWrapper class.
        #
        # Note that this method is primarily intended to called by a scheduled worker.
        def run_migration_job(migration)
          result = create_next_batched_job(migration)

          if result.finished?
            finish_migration(migration)
          elsif result.job_created?
            migration_wrapper.perform(result.next_batched_job)
          end
        end

        # Runs all remaining batched_jobs for a batched_background_migration.
        #
        # This method is intended to be used in a test/dev environment to execute the background
        # migration inline. It should NOT be used in a real environment for any non-trivial migrations.
        def run_remaining_migration_jobs(migration)
          unless Rails.env.development? || Rails.env.test?
            raise 'this method is not intended for use in real environments'
          end

          while migration.cleaning_up?
            run_migration_job(migration)

            migration.reload_last_job
          end
        end

        def run_migration_cleanup(job_class_name, table_name, column_name, job_arguments)
          migration_to_cleanup = migration_for_cleanup(job_class_name, table_name, column_name, job_arguments)

          if migration_to_cleanup.nil?
            if Rails.env.test? || Rails.env.development?
              yield
            else
              raise 'could not find a migration for cleanup that matches the given configuration'
            end
          end

          migration_to_cleanup.batched_jobs.find_each do |failed_job|
            migration_wrapper.perform(failed_job)
          end

          run_remaining_migration_jobs(migration_to_cleanup)
        end

        private

        JobCreationResult = Struct.new(:next_batched_job, :finished) do
          def self.finished
            new(nil, true)
          end

          def self.with_job(job)
            new(job, false)
          end

          def job_created?
            next_batched_job.present?
          end

          alias_method :job_created?, :next_batched_job
          alias_method :finished?, :finished
        end

        attr_reader :migration_wrapper

        def create_next_batched_job(active_migration)
          next_batch_range = find_next_batch_range(active_migration)

          return JobCreationResult.finished if next_batch_range.nil?

          next_batched_job = active_migration.create_batched_job(next_batch_range.min, next_batch_range.max)

          JobCreationResult.with_job(next_batched_job)
        end

        def find_next_batch_range(active_migration)
          batching_strategy = active_migration.batch_class.new
          batch_min_value = active_migration.next_min_value

          next_batch_bounds = batching_strategy.next_batch(
            active_migration.table_name,
            active_migration.column_name,
            batch_min_value: batch_min_value,
            batch_size: active_migration.batch_size)

          return if next_batch_bounds.nil?

          clamped_batch_range(active_migration, next_batch_bounds)
        end

        def clamped_batch_range(active_migration, next_bounds)
          min_value, max_value = next_bounds

          return if min_value > active_migration.max_value

          max_value = max_value.clamp(min_value, active_migration.max_value)

          (min_value..max_value)
        end

        def finish_migration(migration)
          migration.finished!
        end

        def migration_for_cleanup(job_class_name, table_name, column_name, job_arguments)
          BatchedMigration.transaction do
            BatchedMigration
              .for_configuration(job_class_name, table_name, column_name, job_arguments)
              .not_aborted
              .lock
              .first
              .tap { |migration| migration&.cleaning_up! }
          end
        end
      end
    end
  end
end
