# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    InvalidUpstreamStatusError = Class.new(StandardError)

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
      when 'running'
        bridge.run!
      when 'manual'
        bridge.update(status: 'manual')
      when 'scheduled'
        bridge.update(status: 'scheduled')
      else
        raise InvalidUpstreamStatusError
      end
    end
  end
end
