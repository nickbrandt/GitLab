# frozen_string_literal: true

class BuildArtifactEntity < Grape::Entity
  include RequestAwareEntity
  include GitlabRoutingHelper

  alias_method :artifact, :object

  expose :name do |artifact|
    if artifact.file_type == 'archive'
      file_name = artifact.file_in_database
      file_info = "#{artifact.file_type}"
      # To differentiate multiple archives the file name from the database is used or the artifact id
      # file_name  corresponds to `artifact:archives:name` in gitlab-ci.yml
      file_info += file_name ? ":#{file_name.split('.').first}" : ":artifact #{artifact.id}"
    else
      file_info = "#{artifact.file_type}"
    end

    "#{artifact.job.name}:#{file_info}"
  end

  expose :expire_at
  expose :expired?, as: :expired

  expose :path do |artifact|
    fast_download_project_job_artifacts_path(
      artifact.project,
      artifact.job,
      artifact_id: artifact.id
    )
  end

  expose :keep_path, if: -> (*) { artifact.expiring? } do |artifact|
    fast_keep_project_job_artifacts_path(artifact.project, artifact.job)
  end

  expose :browse_path do |artifact|
    fast_browse_project_job_artifacts_path(artifact.project, artifact.job)
  end
end
