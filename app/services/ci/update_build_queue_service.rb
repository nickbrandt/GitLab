# frozen_string_literal: true

module Ci
  class UpdateBuildQueueService
    ##
    # Add a build to the pending builds queue
    #
    def queue_push!(build, metrics = ::Gitlab::Ci::Queue::Metrics)
      in_transaction do
        ::Ci::PendingBuild.create!(build: build, project: project)

        # TODO increment pending builds counter
      end
    end

    ##
    # Remove a build from the pending builds queue
    #
    def queue_pop!(build, metrics = ::Gitlab::Ci::Queue::Metrics)
      in_transaction do
        ::Ci::PendingBuild.find(build.id).destroy!

        # TODO decrement pending builds counter
      end
    end

    ##
    # Unblock runner associated with given project / build
    #
    def execute(build, metrics = ::Gitlab::Ci::Queue::Metrics)
      tick_for(build, build.project.all_runners, metrics)
    end

    private

    def in_transaction
      # TODO ensure that state machine transition transaction is open
      #
      yield
    end


    def tick_for(build, runners, metrics)
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
