# frozen_string_literal: true

module EE
  module BuildFinishedWorker
    def process_build(build)
      unless ::Feature.enabled?(:cancel_pipelines_prior_to_destroy, default_enabled: :yaml)
        ::Ci::Minutes::UpdateBuildMinutesService.new(build.project, nil).execute(build)
      end

      unless build.project.requirements.empty?
        RequirementsManagement::ProcessRequirementsReportsWorker.perform_async(build.id)
      end

      super
    end
  end
end
