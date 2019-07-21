# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    InvalidUpstreamStatusError = Class.new(StandardError)

    def execute(pipeline)
      pipeline.downstream_bridges.each do |bridge|
        bridge.save! if self.class.process_bridge(pipeline.status, bridge)
      end
    end

    def self.process_bridge(status, bridge)
      if ::Ci::Pipeline.bridgeable_statuses.include?(status)
        bridge.status = status
      else
        raise InvalidUpstreamStatusError
      end
    end
  end
end
