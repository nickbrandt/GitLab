# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include Geo::Syncable

  MODEL_CLASS = ::Ci::JobArtifact
  MODEL_FOREIGN_KEY = :artifact_id

  scope :never, -> { where(success: false, retry_count: nil) }

  def self.failed
    if registry_consistency_worker_enabled?
      where(success: false).where.not(retry_count: nil)
    else
      # Would do `super` except it doesn't work with an included scope
      where(success: false)
    end
  end

  def self.registry_consistency_worker_enabled?
    Feature.enabled?(:geo_job_artifact_registry_ssot_sync)
  end

  def self.finder_class
    ::Geo::JobArtifactRegistryFinder
  end

  # When false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    false
  end
end
