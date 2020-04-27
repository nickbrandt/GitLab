# frozen_string_literal: true

class Geo::LfsObjectRegistry < Geo::BaseRegistry
  include ::ShaAttribute
  include ::Geo::Syncable

  MODEL_CLASS = ::LfsObject
  MODEL_FOREIGN_KEY = :lfs_object_id

  sha_attribute :sha256

  belongs_to :lfs_object, class_name: 'LfsObject'

  scope :failed, -> { where(success: false).where.not(retry_count: nil).without_deleted }

  def self.finder_class
    ::Geo::LfsObjectRegistryFinder
  end

  # If false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    false
  end
end
