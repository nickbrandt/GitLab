# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fixes https://gitlab.com/gitlab-org/gitlab/issues/32961
    class FixGitlabComPagesAccessLevel
      include Gitlab::Database::MigrationHelpers

      MIGRATION = 'FixGitlabComPagesAccessLevelBatch'
      BATCH_SIZE = 10_000
      BATCH_TIME = 2.minutes

      # Project
      class Project < ActiveRecord::Base
        include EachBatch

        self.table_name = 'projects'
        self.inheritance_column = :_type_disabled
      end

      def perform
        queue_background_migration_jobs_by_range_at_intervals(
          Project,
          MIGRATION,
          BATCH_TIME,
          batch_size: BATCH_SIZE)
      end
    end
  end
end
