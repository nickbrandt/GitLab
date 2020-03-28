# frozen_string_literal: true

module EE
  module BuildFinishedWorker
    def process_build(build)
      UpdateBuildMinutesService.new(build.project, nil).execute(build)
      # We need to use `reset` on `project` because their AR associations have been cached
      # and `Namespace#namespace_statistics` will return stale data.
      CiMinutesUsageNotifyService.new(build.project.reset).execute

      StoreSecurityScansWorker.perform_async(build.id)

      super
    end
  end
end
