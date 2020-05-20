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
    where(success: false).where.not(retry_count: nil)
  end

  def self.finder_class
    ::Geo::LfsObjectRegistryFinder
  end

  # If false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    false
  end

  def self.delete_for_model_ids(ids)
    ids.map do |id|
      ::Geo::FileRegistryRemovalWorker.perform_async(:lfs, id) # rubocop:disable CodeReuse/Worker
    end
  end
end
