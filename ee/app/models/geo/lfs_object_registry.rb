# frozen_string_literal: true

class Geo::LfsObjectRegistry < Geo::BaseRegistry
  include ::ShaAttribute
  include ::Geo::Syncable

  sha_attribute :sha256

  belongs_to :lfs_object, class_name: 'LfsObject'

  def self.lfs_object_id_in(ids)
    where(lfs_object_id: ids)
  end

  def self.lfs_object_id_not_in(ids)
    where.not(lfs_object_id: ids)
  end
end
