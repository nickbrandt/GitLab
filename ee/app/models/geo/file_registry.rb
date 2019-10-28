# frozen_string_literal: true

class Geo::FileRegistry < Geo::BaseRegistry
  include Geo::Syncable

  scope :attachments, -> { where(file_type: Gitlab::Geo::Replication::USER_UPLOADS_OBJECT_TYPES) }
  scope :failed, -> { where(success: false).where.not(retry_count: nil) }
  scope :fresh, -> { order(created_at: :desc) }
  scope :never, -> { where(success: false, retry_count: nil) }
  scope :uploads, -> { where(file_type: Gitlab::Geo::Replication::UPLOAD_OBJECT_TYPE) }

  self.inheritance_column = 'file_type'

  def self.find_sti_class(file_type)
    if Gitlab::Geo::Replication.object_type_from_user_uploads?(file_type)
      Geo::UploadRegistry
    end
  end

  def self.file_id_in(ids)
    where(file_id: ids)
  end

  def self.file_id_not_in(ids)
    where.not(file_id: ids)
  end

  def self.pluck_file_key
    where(nil).pluck(:file_id)
  end

  def self.with_status(status)
    case status
    when 'synced', 'never', 'failed'
      self.public_send(status) # rubocop: disable GitlabSecurity/PublicSend
    else
      all
    end
  end

  # Returns a synchronization state based on existing attribute values
  #
  # It takes into account things like if a successful replication has been done
  # if there are pending actions or existing errors
  #
  # @return [Symbol] :synced, :never, or :failed
  def synchronization_state
    return :synced if success?
    return :never if retry_count.nil?

    :failed
  end
end
