# frozen_string_literal: true

module EE
  module PipelineSerializer
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    override :preloaded_relations
    def preloaded_relations
      super.concat([
        { triggered_by_pipeline: [:project, :user] },
        { triggered_pipelines: [:project, :user] }
      ])
    end
  end
end
