# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    def execute(pipeline)
      pipeline.downstream_bridges.each(&:inherit_status_from_upstream!)

      if pipeline.bridge_triggered?
        pipeline.source_bridge.inherit_status_from_downstream!(pipeline)
      end
    end
  end
end
