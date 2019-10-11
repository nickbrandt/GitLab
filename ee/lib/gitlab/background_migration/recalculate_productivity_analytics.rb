# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecalculateProductivityAnalytics
      def perform(_start_id, _end_id)
        # Do nothing. Migration is removed.
        # By keeping the class for a while we allow workers to work off for those environments
        # which have scheduled the migration.
        # Will be removed completely in https://gitlab.com/gitlab-org/gitlab/merge_requests/17957
      end
    end
  end
end
