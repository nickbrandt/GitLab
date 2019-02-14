# frozen_string_literal: true

module EE
  module ExpirePipelineCacheWorker
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :update_etag_cache
    def update_etag_cache(pipeline, store)
      super

      triggered_by = pipeline.triggered_by_pipeline
      store.touch(project_pipeline_path(triggered_by.project, triggered_by)) if triggered_by

      pipeline.triggered_pipelines.each do |triggered|
        store.touch(project_pipeline_path(triggered.project, triggered))
      end
    end
  end
end
