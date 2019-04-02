# frozen_string_literal: true

class Geo::FileRegistry < Geo::BaseRegistry
  include Geo::Syncable

  scope :lfs_objects, -> { where(file_type: :lfs) }
  scope :attachments, -> { where(file_type: Geo::FileService::DEFAULT_OBJECT_TYPES) }
  scope :never, -> { where(retry_count: nil) }
  scope :fresh, -> { order(created_at: :desc) }

  self.inheritance_column = 'file_type'

  def self.find_sti_class(file_type)
    if file_type == 'lfs'
      Geo::LfsObjectRegistry
    elsif Geo::FileService::DEFAULT_OBJECT_TYPES.include?(file_type.to_sym)
      Geo::UploadRegistry
    end
  end

  def self.with_status(status)
    case status
    when 'synced'
      synced
    when 'never'
      never
    when 'failed'
      failed
    else
      self
    end
  end

  # Returns a synchronization state based on existing attribute values
  #
  # It takes into account things like if a successful replication has been done
  # if there are pending actions or existing errors
  #
  # @return [Symbol] :never, :failed:, :pending or :synced
  def synchronization_state
    return :synced if success?
    return :never if success.nil? && retry_count.nil?

    :failed
  end
end
