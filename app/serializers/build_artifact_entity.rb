# frozen_string_literal: true

class BuildArtifactEntity < Grape::Entity
  include RequestAwareEntity
  include GitlabRoutingHelper
  include Gitlab::Utils::StrongMemoize

  expose :name do |job|
    job.name
  end

  expose :artifacts_expired?, as: :expired
  expose :artifacts_expire_at, as: :expire_at

  expose :path do |job|
    fast_download_project_job_artifacts_path(project, job, params)
  end

  expose :keep_path, if: -> (*) { job.has_expiring_archive_artifacts? } do |job|
    fast_keep_project_job_artifacts_path(project, job, params)
  end

  expose :browse_path do |job|
    fast_browse_project_job_artifacts_path(project, job, params)
  end

  private

  alias_method :job, :object

  def project
    job.project
  end

  def params
    if file_type.present?
      { file_type: file_type }
    else
      {}
    end
  end

  def file_type
    strong_memoize(:file_type) do
      job.downloadable_artifacts&.first&.file_type
    end
  end
end
