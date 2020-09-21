# frozen_string_literal: true

module Ci
  class UpdateBuildStateService
    include Gitlab::Utils::StrongMemoize

    Result = Struct.new(:status, :backoff, keyword_init: true)

    ACCEPT_TIMEOUT = 5.minutes.freeze

    attr_reader :build, :params, :metrics

    def initialize(build, params, metrics = ::Gitlab::Ci::Trace::Metrics.new)
      @build = build
      @params = params
      @metrics = metrics
    end

    def execute
      overwrite_trace! if has_trace?
      create_pending_state! if accept_available?

      if accept_request?
        accept_build_state!
      else
        validate_build_trace!
        update_build_state!
      end
    end

    private

    def accept_build_state!
      if Time.current - pending_state.created_at > ACCEPT_TIMEOUT
        metrics.increment_trace_operation(operation: :discarded)

        return update_build_state!
      end

      build.trace_chunks.live.find_each do |chunk|
        chunk.schedule_to_persist!
      end

      metrics.increment_trace_operation(operation: :accepted)

      ::Gitlab::Ci::Runner::Backoff.new(pending_state.created_at).then do |backoff|
        Result.new(status: 202, backoff: backoff.to_seconds)
      end
    end

    def overwrite_trace!
      metrics.increment_trace_operation(operation: :overwrite)

      build.trace.set(params[:trace]) if Gitlab::Ci::Features.trace_overwrite?
    end

    def create_pending_state!
      pending_state.created_at
    end

    def validate_build_trace!
      return unless accept_available?

      unless ::Gitlab::Ci::Trace::Checksum.new(build).valid?
        metrics.increment_trace_operation(operation: :invalid)
      end

      return unless chunks_persisted?

      metrics.increment_trace_operation(operation: :finalized)
    end

    def update_build_state!
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

    def accept_available?
      !build_running? && has_checksum? && chunks_migration_enabled?
    end

    def accept_request?
      accept_available? && live_chunks_pending?
    end

    def build_state
      params.dig(:state).to_s
    end

    def has_trace?
      params.dig(:trace).present?
    end

    def has_checksum?
      params.dig(:checksum).present?
    end

    def live_chunks_pending?
      build.trace_chunks.live.any?
    end

    def chunks_persisted?
      build.trace_chunks.any? && !live_chunks_pending?
    end

    def build_running?
      build_state == 'running'
    end

    def pending_state
      strong_memoize(:pending_state) { ensure_pending_state }
    end

    def ensure_pending_state
      Ci::BuildPendingState.create_or_find_by!(
        build_id: build.id,
        state: params.fetch(:state),
        trace_checksum: params.fetch(:checksum),
        failure_reason: params.dig(:failure_reason)
      )
    rescue ActiveRecord::RecordNotFound
      metrics.increment_trace_operation(operation: :conflict)

      build.pending_state
    end

    def chunks_migration_enabled?
      ::Gitlab::Ci::Features.accept_trace?(build.project)
    end
  end
end
