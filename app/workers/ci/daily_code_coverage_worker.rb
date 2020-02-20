# frozen_string_literal: true

module Ci
  class DailyCodeCoverageWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::DailyCodeCoverageService.new.execute(pipeline)
      end
    end
  end
end
