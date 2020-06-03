# frozen_string_literal: true

# Deprecated, shall be removed in 13.2 https://gitlab.com/gitlab-org/gitlab/-/issues/220146
class CreateEvidenceWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :release_evidence
  weight 2

  def perform(release_id)
    release = Release.find_by_id(release_id)
    return unless release

    ::Releases::CreateEvidenceService.new(release, pipeline: nil).execute
  end
end
