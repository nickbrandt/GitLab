# frozen_string_literal: true

class Geo::FileRegistry < Geo::BaseRegistry
  include Geo::Syncable

  scope :lfs_objects, -> { where(file_type: :lfs) }
  scope :attachments, -> { where(file_type: Geo::FileService::DEFAULT_OBJECT_TYPES) }

  self.inheritance_column = 'file_type'

  def self.find_sti_class(file_type)
    if file_type == 'lfs'
      Geo::LfsObjectRegistry
    elsif Geo::FileService::DEFAULT_OBJECT_TYPES.include?(file_type.to_sym)
      Geo::UploadRegistry
    end
  end
end
