# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include Geo::Syncable

  MODEL_CLASS = ::Ci::JobArtifact
  MODEL_FOREIGN_KEY = :artifact_id

  scope :never, -> { where(success: false, retry_count: nil) }

  def self.failed
    where(success: false).where.not(retry_count: nil)
  end

  def self.finder_class
    ::Geo::JobArtifactRegistryFinder
  end

  def self.find_registry_differences(range)
    finder_class.new(current_node_id: Gitlab::Geo.current_node.id).find_registry_differences(range)
  end

  # When false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    false
  end

  # TODO: remove once `success` column has a default value set
  # https://gitlab.com/gitlab-org/gitlab/-/issues/214407
  def self.insert_for_model_ids(artifact_ids)
    records = artifact_ids.map do |artifact_id|
      new(artifact_id: artifact_id, success: false, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.delete_for_model_ids(artifact_ids)
    artifact_ids.map do |artifact_id|
      delete_worker_class.perform_async(:job_artifact, artifact_id)
    end
  end
end
