# frozen_string_literal: true

module Mutations
  module Ci
    class PipelineRetry < Base
      graphql_name 'PipelineRetry'

      authorize :update_pipeline

      def resolve(id:)
        pipeline = authorized_find!(id: id)
        project = pipeline.project

        ::Ci::RetryPipelineService.new(project, current_user).execute(pipeline)
        {
          pipeline: pipeline,
          errors: errors_on_object(pipeline)
        }
      end
    end
  end
end
