# frozen_string_literal: true

module Mutations
  module Ci
    class PipelineDestroy < Base
      graphql_name 'PipelineDestroy'

      authorize :destroy_pipeline

      def resolve(id:)
        pipeline = authorized_find!(id: id)
        project = pipeline.project

        ::Ci::DestroyPipelineService.new(project, current_user).execute(pipeline)
      rescue ActiveRecord::RecordNotFound
        {
          errors: ['Pipeline not found']
        }
      end
    end
  end
end
