# frozen_string_literal: true

class Geo::UploadRegistry < Geo::BaseRegistry
  include Geo::Syncable

  MODEL_CLASS = ::Upload
  MODEL_FOREIGN_KEY = :file_id

  self.table_name = 'file_registry'

  belongs_to :upload, foreign_key: :file_id

  scope :failed, -> { where(success: false).where.not(retry_count: nil) }
  scope :fresh, -> { order(created_at: :desc) }
  scope :never, -> { where(success: false, retry_count: nil) }

  def self.registry_consistency_worker_enabled?
    Feature.enabled?(:geo_file_registry_ssot_sync, default_enabled: true)
  end

  def self.finder_class
    ::Geo::AttachmentRegistryFinder
  end

  def self.delete_worker_class
    ::Geo::FileRegistryRemovalWorker
  end

  # If false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    false
  end

  def self.insert_for_model_ids(attrs)
    records = attrs.map do |file_id, file_type|
      new(file_id: file_id, file_type: file_type, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.delete_for_model_ids(attrs)
    attrs.map do |file_id, file_type|
      delete_worker_class.perform_async(file_type, file_id)
    end
  end

  def self.with_search(query)
    return all if query.nil?

    where(file_id: Geo::Fdw::Upload.search(query))
  end

  def self.with_status(status)
    case status
    when 'synced', 'failed'
      self.public_send(status) # rubocop: disable GitlabSecurity/PublicSend
    # Explained via: https://gitlab.com/gitlab-org/gitlab/-/issues/216049
    when 'pending'
      self.never
    else
      all
    end
  end

  def self.replication_enabled?
    FileUploader.object_store_enabled? ? Gitlab::Geo.current_node.sync_object_storage? : true
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
