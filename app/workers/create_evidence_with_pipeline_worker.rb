# frozen_string_literal: true

class CreateEvidenceWithPipelineWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :release_evidence
  weight 2

  def perform(release_id, pipeline_id)
    release = Release.find_by_id(release_id)
    return unless release

    pipeline = Ci::Pipeline.find_by_id(pipeline_id)

    ::Releases::CreateEvidenceService.new(release, pipeline: pipeline).execute
  end
end
