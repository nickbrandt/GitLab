# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    def execute(pipeline)
      pipeline.downstream_bridges.each do |bridge|
        process_bridge(pipeline.status, bridge)
      end
    end

    def process_bridge(status, bridge)
      case status
      when 'success'
        bridge.success!
      when 'failed'
        bridge.drop!
      when 'canceled'
        bridge.cancel!
      when 'skipped'
        bridge.skip!
      end
    end
  end
end
