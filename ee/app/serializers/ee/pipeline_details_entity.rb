# frozen_string_literal: true

module EE
  module PipelineDetailsEntity
    extend ActiveSupport::Concern

    prepended do
      expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
      expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
    end
  end
end
