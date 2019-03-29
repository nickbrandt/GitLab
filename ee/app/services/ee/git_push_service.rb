# frozen_string_literal: true

module EE
  module GitPushService
    extend ::Gitlab::Utils::Override

    protected

    override :execute_related_hooks
    def execute_related_hooks
      if should_index_commits?
        ::ElasticCommitIndexerWorker.perform_async(project.id, params[:oldrev], params[:newrev])
      end

      super
    end

    private

    def should_index_commits?
      default_branch? &&
        project.use_elasticsearch? &&
        ::Gitlab::Redis::SharedState.with { |redis| !redis.sismember(:elastic_projects_indexing, project.id) }
    end

    override :pipeline_options
    def pipeline_options
      { mirror_update: project.mirror? && project.repository.up_to_date_with_upstream?(branch_name) }
    end
  end
end
