# frozen_string_literal: true

class CreateCrossProjectPipelineWorker
  include ::ApplicationWorker
  include ::PipelineQueue

  def perform(bridge_id)
    ::Ci::Bridge.find(bridge_id).try do |bridge|
      ::Ci::CreateCrossProjectPipelineService
        .new(bridge.project, bridge.user)
        .execute(bridge)
    end
  end
end
