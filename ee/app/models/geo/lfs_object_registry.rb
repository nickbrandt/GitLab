# frozen_string_literal: true

class Geo::LfsObjectRegistry < Geo::BaseRegistry
  include ::ShaAttribute
  include ::Geo::Syncable

  MODEL_CLASS = ::LfsObject
  MODEL_FOREIGN_KEY = :lfs_object_id

  sha_attribute :sha256

  belongs_to :lfs_object, class_name: 'LfsObject'

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
    Feature.enabled?(:geo_lfs_registry_ssot_sync)
  end

  def self.finder_class
    ::Geo::LfsObjectRegistryFinder
  end

  # If false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    false
  end
end
