# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    def execute(pipeline)
      pipeline.downstream_bridges.each(&:inherit_status_from_upstream!)
    end
  end
end
