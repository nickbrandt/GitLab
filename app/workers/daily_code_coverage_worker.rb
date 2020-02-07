# frozen_string_literal: true

class DailyCodeCoverageWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      Ci::DailyCodeCoverageService.new.execute(pipeline)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
