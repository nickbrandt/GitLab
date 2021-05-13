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
      raise InvalidQueueTransition unless transition.to == 'pending'

      transition.within_transaction do
        ::Ci::PendingBuild.create!(build: build, project: build.project)
      end

      # TODO increment pending builds counter
    end

    ##
    # Remove a build from the pending builds queue
    #
    def pop(build, transition)
      raise InvalidQueueTransition unless transition.from == 'pending'

      transition.within_transaction do
        ::Ci::PendingBuild.find_by(build_id: build.id)&.destroy! # rubocop:disable CodeReuse/ActiveRecord
      end

      # TODO decrement pending builds counter
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
  end
end
