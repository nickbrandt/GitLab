# frozen_string_literal: true

module EE
  module BuildFinishedWorker
    def process_build(build)
      UpdateBuildMinutesService.new(build.project, nil).execute(build)

      super

      ChatNotificationWorker.perform_async(build.id) if build.pipeline.chat?
    end
  end
end
