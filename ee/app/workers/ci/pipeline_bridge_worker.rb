# frozen_string_literal: true

module Ci
  class PipelineBridgeWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        ::Ci::PipelineBridgeService
          .new(pipeline.project, pipeline.user)
          .execute(pipeline)
      end
    end
  end
end
