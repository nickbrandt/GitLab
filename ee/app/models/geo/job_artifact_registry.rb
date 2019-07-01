# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include Geo::Syncable

  def self.artifact_id_in(ids)
    where(artifact_id: ids)
  end

  def self.artifact_id_not_in(ids)
    where.not(artifact_id: ids)
  end

  def self.pluck_artifact_key
    where(nil).pluck(:artifact_id)
  end
end
