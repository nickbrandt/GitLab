# frozen_string_literal: true

module Evidences
  class BuildArtifactEntity < Grape::Entity
    include RequestAwareEntity

    expose :url do |job|
      download_project_job_artifacts_url(project, job)
    end

    private

    alias_method :job, :object

    def project
      job.project
    end
  end
end
