# frozen_string_literal: true

module Ci
  class PipelineBridgeService < ::BaseService
    def execute(pipeline)
      pipeline.bridged_jobs.each do |bridged_job|
        bridged_job.update(status: pipeline.status)
      end
    end
  end
end
