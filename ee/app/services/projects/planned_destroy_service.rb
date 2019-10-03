# frozen_string_literal: true

module Projects
  class PlannedDestroyService < DestroyService
    def execute
      project.update_attribute(:pending_delete, true)

      # Ensure no repository +deleted paths are kept,
      # regardless of any issue with the ProjectDestroyWorker
      # job process.
      schedule_stale_repos_removal

      super
    end
  end
end
