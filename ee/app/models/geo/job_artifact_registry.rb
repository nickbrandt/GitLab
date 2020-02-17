# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include Geo::Syncable

  MODEL_CLASS = ::Ci::JobArtifact
  MODEL_FOREIGN_KEY = :artifact_id

  scope :never, -> { where(success: false, retry_count: nil) }

  def self.failed
    if Feature.enabled?(:geo_job_artifact_registry_ssot_sync)
      where(success: false).where.not(retry_count: nil)
    else
      # Would do `super` except it doesn't work with an included scope
      where(success: false)
    end
  end
end
