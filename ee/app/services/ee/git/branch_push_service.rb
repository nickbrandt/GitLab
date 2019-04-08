# frozen_string_literal: true

module EE
  module Git
    module BranchPushService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        enqueue_elasticsearch_indexing

        super
      end

      private

      def enqueue_elasticsearch_indexing
        return unless should_index_commits?

        ::ElasticCommitIndexerWorker.perform_async(
          project.id,
          params[:oldrev],
          params[:newrev]
        )
      end

      def should_index_commits?
        return false unless default_branch?
        return false unless project.use_elasticsearch?

        # Check that we're not already indexing this project
        ::Gitlab::Redis::SharedState.with do |redis|
          !redis.sismember(:elastic_projects_indexing, project.id)
        end
      end
    end
  end
end
