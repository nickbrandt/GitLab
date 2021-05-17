# frozen_string_literal: true

module Ci
  class UpdateBuildQueueService
    InvalidQueueTransition = Class.new(StandardError)

    attr_reader :metrics

    def initialize(metrics = ::Gitlab::Ci::Queue::Metrics)
      @metrics = metrics
    end

    ##
    # Add a build to the pending builds queue
    #
    def push(build, transition)
      return unless maintain_pending_builds_queue?

      raise InvalidQueueTransition unless transition.to == 'pending'

      transition.within_transaction do
        ::Ci::PendingBuild.create!(build: build, project: build.project).tap do
          metrics.increment_queue_operation(:build_queue_push)
        end
      end
    end

    ##
    # Remove a build from the pending builds queue
    #
    def pop(build, transition)
      return unless maintain_pending_builds_queue?

      raise InvalidQueueTransition unless transition.from == 'pending'

      transition.within_transaction do
        ::Ci::PendingBuild.find_by(build_id: build.id).tap do |queued| # rubocop:disable CodeReuse/ActiveRecord
          next unless queued.present?

          queued.destroy!

          metrics.increment_queue_operation(:build_queue_pop)
        end
      end
    end

    ##
    # Unblock runner associated with given project / build
    #
    def tick(build)
      tick_for(build, build.project.all_runners)
    end

    private

    def tick_for(build, runners)
      runners = runners.with_recent_runner_queue
      runners = runners.with_tags if Feature.enabled?(:ci_preload_runner_tags, default_enabled: :yaml)

      metrics.observe_active_runners(-> { runners.to_a.size })

      runners.each do |runner|
        metrics.increment_runner_tick(runner)

        runner.pick_build!(build)
      end
    end

    def maintain_pending_builds_queue?
      Feature.enabled?(:ci_pending_builds_queue_maintain, default_enabled: :yaml)
    end
  end
end
