# frozen_string_literal: true

module EE
  module Ci
    module PipelineTriggerService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      private

      override :create_pipeline_from_job
      def create_pipeline_from_job(job)
        # this check is to not leak the presence of the project if user cannot read it
        return unless can?(job.user, :read_project, project)

        return error("400 Job has to be running", 400) unless job.running?

        pipeline = ::Ci::CreatePipelineService.new(project, job.user, ref: params[:ref])
          .execute(:pipeline, ignore_skip_ci: true) do |pipeline|
            source = job.sourced_pipelines.build(
              source_pipeline: job.pipeline,
              source_project: job.project,
              pipeline: pipeline,
              project: project)

            pipeline.source_pipeline = source
            pipeline.variables.build(variables)
          end

        if pipeline.persisted?
          success(pipeline: pipeline)
        else
          error(pipeline.errors.messages, 400)
        end
      end

      override :job_from_token
      def job_from_token
        strong_memoize(:job) do
          ::Ci::Build.find_by_token(params[:token].to_s)
        end
      end
    end
  end
end
