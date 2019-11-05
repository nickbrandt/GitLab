# frozen_string_literal: true

class Geo::UploadRegistry < Geo::BaseRegistry
  include Geo::Syncable

  self.table_name = 'file_registry'

  belongs_to :upload, foreign_key: :file_id

  scope :failed, -> { where(success: false).where.not(retry_count: nil) }
  scope :fresh, -> { order(created_at: :desc) }
  scope :never, -> { where(success: false, retry_count: nil) }

  def self.file_id_in(ids)
    where(file_id: ids)
  end

  def self.file_id_not_in(ids)
    where.not(file_id: ids)
  end

  def self.pluck_file_key
    where(nil).pluck(:file_id)
  end

  def self.with_search(query)
    return all if query.nil?

    where(file_id: Geo::Fdw::Upload.search(query))
  end

  def self.with_status(status)
    case status
    when 'synced', 'never', 'failed'
      self.public_send(status) # rubocop: disable GitlabSecurity/PublicSend
    else
      all
    end
  end

  def file
    upload&.path || s_('Removed %{type} with id %{id}') % { type: file_type, id: file_id }
  end

  def project
    return upload.model if upload&.model.is_a?(Project)
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
