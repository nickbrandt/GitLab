# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    def execute(pipeline)
      pipeline.downstream_bridges.each do |bridged_job|
        process_bridged_job(pipeline.status, bridged_job)
      end
    end

    def process_bridged_job(status, job)
      case status
      when 'success'
        job.success!
      when 'failed'
        job.drop!
      when 'canceled'
        job.cancel!
      when 'skipped'
        job.skip!
      end
    end
  end
end
