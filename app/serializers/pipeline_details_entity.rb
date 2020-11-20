# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :project, using: ProjectEntity

  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :artifacts do |pipeline, options|
      artifacts = pipeline.downloadable_artifacts.map.with_index do |artifact, index|
        ::Ci::BuildArtifactPresenter.new(artifact, display_index: index + 1)  # rubocop:disable CodeReuse/Presenter
      end

      BuildArtifactEntity.represent(artifacts, options)
    end
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
