module EE
  module Ci
    module PipelinePresenter
      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 'Pipeline activity limit exceeded!',
        size_limit_exceeded: 'Pipeline size limit exceeded!'
      }.freeze

      def expose_security_dashboard?
        any_report_artifact_for_type(:sast) ||
          any_report_artifact_for_type(:dependency_scanning) ||
          any_report_artifact_for_type(:dast) ||
          any_report_artifact_for_type(:container_scanning)
      end

      def downloadable_path_for_report_type(file_type)
        if (job_artifact = report_artifact_for_file_type(file_type)) &&
            can?(current_user, :read_build, job_artifact.job)
          return download_project_job_artifacts_path(
            job_artifact.project,
            job_artifact.job,
            file_type: file_type,
            proxy: true)
        end

        if (build_artifact = legacy_report_artifact_for_file_type(file_type)) &&
            can?(current_user, :read_build, build_artifact.build)
          return raw_project_job_artifacts_path(
            build_artifact.build.project,
            build_artifact.build,
            path: build_artifact.path)
        end
      end
    end
  end
end
