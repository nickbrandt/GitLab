# frozen_string_literal: true

module Ci
  class DeleteProjectJobArtifactsWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    idempotent!

    # rubocop: disable Cop/DestroyAll
    def perform(project_id)
      ::Project.find_by_id(project_id).try do |project|
        project.job_artifacts.erasable.each_batch { |artifacts| artifacts.destroy_all }
      end
    end
    # rubocop: enable Cop/DestroyAll
  end
end
