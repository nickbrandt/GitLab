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

  # TODO: remove once `success` column has a default value set
  # https://gitlab.com/gitlab-org/gitlab/-/issues/214407
  def self.insert_for_model_ids(ids)
    records = ids.map do |id|
      new(artifact_id: id, success: false, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.replication_enabled?
    JobArtifactUploader.object_store_enabled? ? Gitlab::Geo.current_node.sync_object_storage? : true
  end
end
