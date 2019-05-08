# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        ::Ci::PipelineBridgeStatusService
          .new(pipeline.project, pipeline.user)
          .execute(pipeline)
      end
    end
  end
end
