# frozen_string_literal: true

module Ci
  class CreateCrossProjectPipelineWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    # rubocop:disable CodeReuse/ActiveRecord
    def perform(bridge_id)
      ::Ci::Bridge.find_by(id: bridge_id).try do |bridge|
        ::Ci::CreateCrossProjectPipelineService
          .new(bridge.project, bridge.user)
          .execute(bridge)
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
