# frozen_string_literal: true

module Ci
  class InitialPipelineProcessService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      Ci::PipelineRunnersMatchingValidationService.new(pipeline).execute
      Ci::ProcessPipelineService.new(pipeline).execute
    end
  end
end
