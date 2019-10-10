# frozen_string_literal: true

# Worker for storing security reports into the database.
#
class StoreSecurityReportsWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(pipeline_id)
    Ci::Pipeline.find(pipeline_id).try do |pipeline|
      break unless pipeline.project.can_store_security_reports?

      ::Security::StoreReportsService.new(pipeline).execute
    end
  end
end
