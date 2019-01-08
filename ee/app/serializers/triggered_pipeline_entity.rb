# frozen_string_literal: true

class TriggeredPipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, using: UserEntity
  expose :active?, as: :active
  expose :coverage
  expose :source

  expose :path do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :details do
    expose :detailed_status, as: :status, with: DetailedStatusEntity
    expose :ordered_stages, as: :stages, using: StageEntity, if: -> (_, opts) { expand?(opts) }
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity, if: -> (_, opts) { expand_for_path?(opts, :triggered_by) }
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity, if: -> (_, opts) { expand_for_path?(opts, :triggered) }

  expose :project, using: ProjectEntity

  private

  alias_method :pipeline, :object

  def detailed_status
    pipeline.detailed_status(request.current_user)
  end

  def expand?(opts)
    opts[:expanded].to_a.include?(pipeline.id)
  end

  def expand_for_path?(opts, path)
    opts[:attr_path].last == path && expand?(opts)
  end
end
