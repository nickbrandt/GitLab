# frozen_string_literal: true

module Ci
  class UpdateBuildStateService
    Result = Struct.new(:status, keyword_init: true)

    ACCEPT_TIMEOUT = 5.minutes.freeze

    attr_reader :build, :params, :metrics

    def initialize(build, params, metrics = ::Gitlab::Ci::Trace::Metrics.new)
      @build = build
      @params = params
      @metrics = metrics
    end

    def execute
      overwrite_trace! if has_trace?

      if accept_request?
        accept_build_state!
      else
        update_build_state!
      end
    end

    private

    def build_state
      params.dig(:state).to_s
    end

    def has_trace?
      params.dig(:trace).present?
    end

    def has_checksum?
      params.dig(:checksum).present?
    end

    def has_chunks?
      build.trace_chunks.any?
    end

    def live_chunks_pending?
      build.trace_chunks.live.any?
    end

    def build_running?
      build_state == 'running'
    end

    def accept_available?
      !build_running? && has_checksum? && chunks_migration_enabled?
    end

    def accept_request?
      accept_available? && live_chunks_pending?
    end

    def chunks_migration_enabled?
      Feature.enabled?(:ci_enable_live_trace, build.project)
    end

    def accept_build_state!
      # TODO, persist ci_build_state if not present (find or create)

      build.trace_chunks.live.find_each do |chunk|
        chunk.schedule_to_persist!
      end

      metrics.increment_trace_operation(operation: :accepted)

      Result.new(status: 202)
    end

    def overwrite_trace!
      metrics.increment_trace_operation(operation: :overwrite)

      # TODO, disable in FF
      build.trace.set(params[:trace])
    end

    def update_build_state!
      if accept_available? && has_chunks?
        metrics.increment_trace_operation(operation: :finalized)
      end

      case build_state
      when 'running'
        build.touch if build.needs_touch?

        Result.new(status: 200)
      when 'success'
        build.success!

        Result.new(status: 200)
      when 'failed'
        build.drop!(params[:failure_reason] || :unknown_failure)

        Result.new(status: 200)
      else
        Result.new(status: 400)
      end
    end
  end
end
