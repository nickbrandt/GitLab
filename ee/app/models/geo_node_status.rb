# frozen_string_literal: true

class GeoNodeStatus < ApplicationRecord
  include ShaAttribute

  belongs_to :geo_node

  delegate :selective_sync_type, to: :geo_node

  after_initialize :initialize_feature_flags

  attr_accessor :storage_shards

  attr_accessor :attachments_replication_enabled, :lfs_objects_replication_enabled, :job_artifacts_replication_enabled,
                :container_repositories_replication_enabled, :design_repositories_replication_enabled, :repositories_replication_enabled,
                :repository_verification_enabled

  # Prometheus metrics, no need to store them in the database
  attr_accessor :event_log_max_id, :repository_created_max_id, :repository_updated_max_id,
                :repository_deleted_max_id, :repository_renamed_max_id, :repositories_changed_max_id,
                :lfs_object_deleted_max_id, :job_artifact_deleted_max_id,
                :lfs_objects_registry_count, :job_artifacts_registry_count, :attachments_registry_count,
                :hashed_storage_migrated_max_id, :hashed_storage_attachments_max_id,
                :repositories_checked_count, :repositories_checked_failed_count

  sha_attribute :storage_configuration_digest

  alias_attribute :repositories_count, :projects_count
  alias_attribute :wikis_count, :projects_count

  attribute_method_suffix '_timestamp', '_timestamp='

  alias_attribute :last_successful_status_check_timestamp, :last_successful_status_check_at_timestamp
  alias_attribute :last_event_timestamp, :last_event_date_timestamp
  alias_attribute :cursor_last_event_timestamp, :cursor_last_event_date_timestamp

  RESOURCE_STATUS_FIELDS = %w(
    repositories_synced_count
    repositories_failed_count
    lfs_objects_count
    lfs_objects_synced_count
    lfs_objects_failed_count
    attachments_count
    attachments_synced_count
    attachments_failed_count
    wikis_synced_count
    wikis_failed_count
    job_artifacts_count
    job_artifacts_synced_count
    job_artifacts_failed_count
    repositories_verified_count
    repositories_verification_failed_count
    wikis_verified_count
    wikis_verification_failed_count
    lfs_objects_synced_missing_on_primary_count
    job_artifacts_synced_missing_on_primary_count
    attachments_synced_missing_on_primary_count
    repositories_checksummed_count
    repositories_checksum_failed_count
    repositories_checksum_mismatch_count
    wikis_checksummed_count
    wikis_checksum_failed_count
    wikis_checksum_mismatch_count
    repositories_retrying_verification_count
    wikis_retrying_verification_count
    projects_count
    container_repositories_count
    container_repositories_synced_count
    container_repositories_failed_count
    container_repositories_registry_count
    design_repositories_count
    design_repositories_synced_count
    design_repositories_failed_count
    package_files_count
    package_files_checksummed_count
    package_files_checksum_failed_count
  ).freeze

  # Be sure to keep this consistent with Prometheus naming conventions
  PROMETHEUS_METRICS = {
    db_replication_lag_seconds: 'Database replication lag (seconds)',
    repositories_replication_enabled: 'Boolean denoting if replication is enabled for Repositories',
    repositories_count: 'Total number of repositories available on primary',
    repositories_synced_count: 'Number of repositories synced on secondary',
    repositories_failed_count: 'Number of repositories failed to sync on secondary',
    wikis_synced_count: 'Number of wikis synced on secondary',
    wikis_failed_count: 'Number of wikis failed to sync on secondary',
    repositories_checksummed_count: 'Number of repositories checksummed on primary',
    repositories_checksum_failed_count: 'Number of repositories failed to calculate the checksum on primary',
    wikis_checksummed_count: 'Number of wikis checksummed on primary',
    wikis_checksum_failed_count: 'Number of wikis failed to calculate the checksum on primary',
    repositories_verified_count: 'Number of repositories verified on secondary',
    repositories_verification_failed_count: 'Number of repositories failed to verify on secondary',
    repositories_checksum_mismatch_count: 'Number of repositories that checksum mismatch on secondary',
    wikis_verified_count: 'Number of wikis verified on secondary',
    wikis_verification_failed_count: 'Number of wikis failed to verify on secondary',
    wikis_checksum_mismatch_count: 'Number of wikis that checksum mismatch on secondary',
    lfs_objects_replication_enabled: 'Boolean denoting if replication is enabled for LFS Objects',
    lfs_objects_count: 'Total number of syncable LFS objects available on primary',
    lfs_objects_synced_count: 'Number of syncable LFS objects synced on secondary',
    lfs_objects_failed_count: 'Number of syncable LFS objects failed to sync on secondary',
    lfs_objects_registry_count: 'Number of LFS objects in the registry',
    lfs_objects_synced_missing_on_primary_count: 'Number of LFS objects marked as synced due to the file missing on the primary',
    job_artifacts_replication_enabled: 'Boolean denoting if replication is enabled for Job Artifacts',
    job_artifacts_count: 'Total number of syncable job artifacts available on primary',
    job_artifacts_synced_count: 'Number of syncable job artifacts synced on secondary',
    job_artifacts_failed_count: 'Number of syncable job artifacts failed to sync on secondary',
    job_artifacts_registry_count: 'Number of job artifacts in the registry',
    job_artifacts_synced_missing_on_primary_count: 'Number of job artifacts marked as synced due to the file missing on the primary',
    attachments_replication_enabled: 'Boolean denoting if replication is enabled for Attachments',
    attachments_count: 'Total number of syncable file attachments available on primary',
    attachments_synced_count: 'Number of syncable file attachments synced on secondary',
    attachments_failed_count: 'Number of syncable file attachments failed to sync on secondary',
    attachments_registry_count: 'Number of attachments in the registry',
    attachments_synced_missing_on_primary_count: 'Number of attachments marked as synced due to the file missing on the primary',
    replication_slots_count: 'Total number of replication slots on the primary',
    replication_slots_used_count: 'Number of replication slots in use on the primary',
    replication_slots_max_retained_wal_bytes: 'Maximum number of bytes retained in the WAL on the primary',
    last_event_id: 'Database ID of the latest event log entry on the primary',
    last_event_timestamp: 'Time of the latest event log entry on the primary',
    cursor_last_event_id: 'Last database ID of the event log processed by the secondary',
    cursor_last_event_timestamp: 'Time of the event log processed by the secondary',
    last_successful_status_check_timestamp: 'Time when Geo node status was updated internally',
    status_message: 'Summary of health status',
    event_log_max_id: 'Highest ID present in the Geo event log',
    repository_created_max_id: 'Highest ID present in repositories created',
    repository_updated_max_id: 'Highest ID present in repositories updated',
    repository_deleted_max_id: 'Highest ID present in repositories deleted',
    repository_renamed_max_id: 'Highest ID present in repositories renamed',
    repositories_changed_max_id: 'Highest ID present in repositories changed',
    lfs_object_deleted_max_id: 'Highest ID present in LFS objects deleted',
    job_artifact_deleted_max_id: 'Highest ID present in job artifacts deleted',
    hashed_storage_migrated_max_id: 'Highest ID present in projects migrated to hashed storage',
    hashed_storage_attachments_max_id: 'Highest ID present in attachments migrated to hashed storage',
    repositories_checked_count: 'Number of repositories checked',
    repositories_checked_failed_count: 'Number of failed repositories checked',
    repositories_retrying_verification_count: 'Number of repositories verification failures that Geo is actively trying to correct on secondary',
    wikis_retrying_verification_count: 'Number of wikis verification failures that Geo is actively trying to correct on secondary',
    container_repositories_replication_enabled: 'Boolean denoting if replication is enabled for Container Repositories',
    container_repositories_count: 'Total number of syncable container repositories available on primary',
    container_repositories_synced_count: 'Number of syncable container repositories synced on secondary',
    container_repositories_failed_count: 'Number of syncable container repositories failed to sync on secondary',
    container_repositories_registry_count: 'Number of container repositories in the registry',
    design_repositories_replication_enabled: 'Boolean denoting if replication is enabled for Design Repositories',
    design_repositories_count: 'Total number of syncable design repositories available on primary',
    design_repositories_synced_count: 'Number of syncable design repositories synced on secondary',
    design_repositories_failed_count: 'Number of syncable design repositories failed to sync on secondary',
    design_repositories_registry_count: 'Number of design repositories in the registry',
    package_files_count: 'Number of package files on primary',
    package_files_checksummed_count: 'Number of package files checksummed on primary',
    package_files_checksum_failed_count: 'Number of package files failed to checksum on primary'
  }.freeze

  EXPIRATION_IN_MINUTES = 10
  HEALTHY_STATUS = 'Healthy'.freeze
  UNHEALTHY_STATUS = 'Unhealthy'.freeze

  def self.alternative_status_store_accessor(attr_names)
    attr_names.each do |attr_name|
      define_method(attr_name) do
        status[attr_name].nil? ? read_attribute(attr_name) : status[attr_name].to_i
      end

      define_method("#{attr_name}=") do |val|
        status[attr_name] = val.nil? ? nil : val.to_i

        return unless self.class.column_names.include?(attr_name)

        write_attribute(attr_name, val)
      end
    end
  end

  # We migrated from attributes stored in individual columns to
  # a single JSONB hash. To create accessors method for every fields in hash we could use
  # Rails embeded store_accessor but in this case we won't have smooth update procedure.
  # The method "alternative_status_store_accessor" does actually the same that store_accessor would
  # but it uses the old fashioned fields in case the new ones are not set yet. We also casting the type into integer when
  # we set the value to preserve the old behaviour.
  alternative_status_store_accessor RESOURCE_STATUS_FIELDS

  def self.current_node_status
    current_node = Gitlab::Geo.current_node
    return unless current_node

    status = current_node.find_or_build_status

    status.load_data_from_current_node

    status.save if Gitlab::Geo.primary?

    status
  end

  def self.fast_current_node_status
    attrs = Rails.cache.read(cache_key)

    if attrs
      new(attrs)
    else
      spawn_worker
      nil
    end
  end

  def self.spawn_worker
    ::Geo::MetricsUpdateWorker.perform_async # rubocop:disable CodeReuse/Worker
  end

  def self.cache_key
    "geo-node:#{Gitlab::Geo.current_node.id}:status"
  end

  def self.from_json(json_data)
    json_data.slice!(*allowed_params)

    GeoNodeStatus.new(HashWithIndifferentAccess.new(json_data))
  end

  EXCLUDED_PARAMS = %w[id created_at].freeze
  EXTRA_PARAMS = %w[
    last_event_timestamp
    cursor_last_event_timestamp
    storage_shards
  ].freeze

  def self.allowed_params
    self.column_names - EXCLUDED_PARAMS + EXTRA_PARAMS
  end

  def initialize_feature_flags
    self.attachments_replication_enabled = Geo::UploadRegistry.replication_enabled?
    self.container_repositories_replication_enabled = Geo::ContainerRepositoryRegistry.replication_enabled?
    self.design_repositories_replication_enabled = Geo::DesignRegistry.replication_enabled?
    self.job_artifacts_replication_enabled = Geo::JobArtifactRegistry.replication_enabled?
    self.lfs_objects_replication_enabled = Geo::LfsObjectRegistry.replication_enabled?
    self.repositories_replication_enabled = Geo::ProjectRegistry.replication_enabled?
    self.repository_verification_enabled = Gitlab::Geo.repository_verification_enabled?
  end

  def update_cache!
    Rails.cache.write(self.class.cache_key, attributes)
  end

  def load_data_from_current_node
    latest_event = Geo::EventLog.latest_event
    self.last_event_id = latest_event&.id
    self.last_event_date = latest_event&.created_at
    self.last_successful_status_check_at = Time.now

    self.storage_shards = StorageShard.all
    self.storage_configuration_digest = StorageShard.build_digest

    self.version = Gitlab::VERSION
    self.revision = Gitlab.revision

    self.projects_count = geo_node.projects.count

    load_status_message
    load_event_data
    load_primary_data
    load_secondary_data
    load_repository_check_data
    load_verification_data
  end

  def current_cursor_last_event_id
    return unless Gitlab::Geo.secondary?

    min_gap_id = ::Gitlab::Geo::EventGapTracking.min_gap_id
    last_processed_id = Geo::EventLogState.last_processed&.event_id

    [min_gap_id, last_processed_id].compact.min
  end

  def healthy?
    !outdated? && status_message_healthy?
  end

  def health
    status_message
  end

  def health_status
    healthy? ? HEALTHY_STATUS : UNHEALTHY_STATUS
  end

  def outdated?
    return false unless updated_at

    updated_at < EXPIRATION_IN_MINUTES.minutes.ago
  end

  def status_message_healthy?
    status_message.blank? || status_message == HEALTHY_STATUS
  end

  def attribute_timestamp(attr)
    self[attr].to_i
  end

  def attribute_timestamp=(attr, value)
    self[attr] = Time.at(value)
  end

  def self.percentage_methods
    @percentage_methods || []
  end

  def self.attr_in_percentage(attr_name, count, total)
    method_name = "#{attr_name}_in_percentage"
    @percentage_methods ||= []
    @percentage_methods << method_name

    define_method(method_name) do
      return 0 if self[total].to_i.zero?

      (self[count].to_f / self[total].to_f) * 100.0
    end
  end

  attr_in_percentage :repositories_synced,           :repositories_synced_count,           :repositories_count
  attr_in_percentage :repositories_checksummed,      :repositories_checksummed_count,      :repositories_count
  attr_in_percentage :repositories_verified,         :repositories_verified_count,         :repositories_count
  attr_in_percentage :repositories_checked,          :repositories_checked_count,          :repositories_count
  attr_in_percentage :wikis_synced,                  :wikis_synced_count,                  :wikis_count
  attr_in_percentage :wikis_checksummed,             :wikis_checksummed_count,             :wikis_count
  attr_in_percentage :wikis_verified,                :wikis_verified_count,                :wikis_count
  attr_in_percentage :lfs_objects_synced,            :lfs_objects_synced_count,            :lfs_objects_count
  attr_in_percentage :job_artifacts_synced,          :job_artifacts_synced_count,          :job_artifacts_count
  attr_in_percentage :attachments_synced,            :attachments_synced_count,            :attachments_count
  attr_in_percentage :replication_slots_used,        :replication_slots_used_count,        :replication_slots_count
  attr_in_percentage :container_repositories_synced, :container_repositories_synced_count, :container_repositories_count
  attr_in_percentage :design_repositories_synced,    :design_repositories_synced_count,    :design_repositories_count
  attr_in_percentage :package_files_checksummed,     :package_files_checksummed_count,     :package_files_count

  def storage_shards_match?
    return true if geo_node.primary?
    return false unless storage_configuration_digest && primary_storage_digest

    storage_configuration_digest == primary_storage_digest
  end

  def [](key)
    public_send(key) # rubocop:disable GitlabSecurity/PublicSend
  end

  private

  def load_status_message
    self.status_message =
      begin
        HealthCheck::Utils.process_checks(['geo'])
      rescue NotImplementedError => e
        e.to_s
      end
  end

  def load_event_data
    self.event_log_max_id = Geo::EventLog.maximum(:id)
    self.repository_created_max_id = Geo::RepositoryCreatedEvent.maximum(:id)
    self.repository_updated_max_id = Geo::RepositoryUpdatedEvent.maximum(:id)
    self.repository_deleted_max_id = Geo::RepositoryDeletedEvent.maximum(:id)
    self.repository_renamed_max_id = Geo::RepositoryRenamedEvent.maximum(:id)
    self.repositories_changed_max_id = Geo::RepositoriesChangedEvent.maximum(:id)
    self.lfs_object_deleted_max_id = Geo::LfsObjectDeletedEvent.maximum(:id)
    self.job_artifact_deleted_max_id = Geo::JobArtifactDeletedEvent.maximum(:id)
    self.hashed_storage_migrated_max_id = Geo::HashedStorageMigratedEvent.maximum(:id)
    self.hashed_storage_attachments_max_id = Geo::HashedStorageAttachmentsEvent.maximum(:id)
  end

  def load_primary_data
    return unless Gitlab::Geo.primary?

    self.lfs_objects_count = LfsObject.count
    self.job_artifacts_count = Ci::JobArtifact.not_expired.count
    self.attachments_count = Upload.count

    self.replication_slots_count = geo_node.replication_slots_count
    self.replication_slots_used_count = geo_node.replication_slots_used_count
    self.replication_slots_max_retained_wal_bytes = geo_node.replication_slots_max_retained_wal_bytes
  end

  def load_secondary_data
    return unless Gitlab::Geo.secondary?

    self.db_replication_lag_seconds = Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds
    self.cursor_last_event_id = current_cursor_last_event_id
    self.cursor_last_event_date = Geo::EventLog.find_by(id: self.cursor_last_event_id)&.created_at
    self.repositories_synced_count = registries_for_synced_projects(:repository).count
    self.repositories_failed_count = registries_for_failed_projects(:repository).count
    self.wikis_synced_count = registries_for_synced_projects(:wiki).count
    self.wikis_failed_count = registries_for_failed_projects(:wiki).count

    load_lfs_objects_data
    load_job_artifacts_data
    load_attachments_data
    load_container_registry_data
    load_designs_data
  end

  def load_lfs_objects_data
    return unless lfs_objects_replication_enabled

    self.lfs_objects_count = lfs_objects_finder.count_syncable
    self.lfs_objects_synced_count = lfs_objects_finder.count_synced
    self.lfs_objects_failed_count = lfs_objects_finder.count_failed
    self.lfs_objects_registry_count = lfs_objects_finder.count_registry
    self.lfs_objects_synced_missing_on_primary_count = lfs_objects_finder.count_synced_missing_on_primary
  end

  def load_job_artifacts_data
    return unless job_artifacts_replication_enabled

    self.job_artifacts_count = job_artifacts_finder.count_syncable
    self.job_artifacts_synced_count = job_artifacts_finder.count_synced
    self.job_artifacts_failed_count = job_artifacts_finder.count_failed
    self.job_artifacts_registry_count = job_artifacts_finder.count_registry
    self.job_artifacts_synced_missing_on_primary_count = job_artifacts_finder.count_synced_missing_on_primary
  end

  def load_attachments_data
    return unless attachments_replication_enabled

    self.attachments_count = attachments_finder.count_syncable
    self.attachments_synced_count = attachments_finder.count_synced
    self.attachments_failed_count = attachments_finder.count_failed
    self.attachments_registry_count = attachments_finder.count_registry
    self.attachments_synced_missing_on_primary_count = attachments_finder.count_synced_missing_on_primary
  end

  def load_container_registry_data
    return unless container_repositories_replication_enabled

    self.container_repositories_count = container_registry_finder.count_syncable
    self.container_repositories_synced_count = container_registry_finder.count_synced
    self.container_repositories_failed_count = container_registry_finder.count_failed
    self.container_repositories_registry_count = container_registry_finder.count_registry
  end

  def load_designs_data
    return unless design_repositories_replication_enabled

    self.design_repositories_count = design_registry_finder.count_syncable
    self.design_repositories_synced_count = design_registry_finder.count_synced
    self.design_repositories_failed_count = design_registry_finder.count_failed
    self.design_repositories_registry_count = design_registry_finder.count_registry
  end

  def load_repository_check_data
    if Gitlab::Geo.primary?
      self.repositories_checked_count = Project.where.not(last_repository_check_at: nil).count
      self.repositories_checked_failed_count = Project.where(last_repository_check_failed: true).count
    elsif Gitlab::Geo.secondary?
      self.repositories_checked_count = Geo::ProjectRegistry.where.not(last_repository_check_at: nil).count
      self.repositories_checked_failed_count = Geo::ProjectRegistry.where(last_repository_check_failed: true).count
    end
  end

  def load_verification_data
    return unless repository_verification_enabled

    if Gitlab::Geo.primary?
      self.repositories_checksummed_count = repository_verification_finder.count_verified_repositories
      self.repositories_checksum_failed_count = repository_verification_finder.count_verification_failed_repositories
      self.wikis_checksummed_count = repository_verification_finder.count_verified_wikis
      self.wikis_checksum_failed_count = repository_verification_finder.count_verification_failed_wikis
      self.package_files_count = Geo::PackageFileReplicator.primary_total_count
      self.package_files_checksummed_count = Geo::PackageFileReplicator.checksummed_count
      self.package_files_checksum_failed_count = Geo::PackageFileReplicator.checksum_failed_count
    elsif Gitlab::Geo.secondary?
      self.repositories_verified_count = registries_for_verified_projects(:repository).count
      self.repositories_verification_failed_count = registries_for_verification_failed_projects(:repository).count
      self.repositories_checksum_mismatch_count = registries_for_mismatch_projects(:repository).count
      self.wikis_verified_count = registries_for_verified_projects(:wiki).count
      self.wikis_verification_failed_count = registries_for_verification_failed_projects(:wiki).count
      self.wikis_checksum_mismatch_count = registries_for_mismatch_projects(:wiki).count
      self.repositories_retrying_verification_count = registries_retrying_verification(:repository).count
      self.wikis_retrying_verification_count = registries_retrying_verification(:wiki).count
    end
  end

  def primary_storage_digest
    @primary_storage_digest ||= Gitlab::Geo.primary_node.find_or_build_status.storage_configuration_digest
  end

  def attachments_finder
    @attachments_finder ||= Geo::AttachmentRegistryFinder.new(current_node_id: geo_node.id)
  end

  def lfs_objects_finder
    @lfs_objects_finder ||= Geo::LfsObjectRegistryFinder.new(current_node_id: geo_node.id)
  end

  def job_artifacts_finder
    @job_artifacts_finder ||= Geo::JobArtifactRegistryFinder.new(current_node_id: geo_node.id)
  end

  def container_registry_finder
    @container_registry_finder ||= Geo::ContainerRepositoryRegistryFinder.new(current_node_id: geo_node.id)
  end

  def design_registry_finder
    @design_registry_finder ||= Geo::DesignRegistryFinder.new(current_node_id: geo_node.id)
  end

  def registries_for_synced_projects(type)
    Geo::ProjectRegistrySyncedFinder
      .new(current_node: geo_node, type: type)
      .execute
  end

  def registries_for_failed_projects(type)
    Geo::ProjectRegistrySyncFailedFinder
      .new(current_node: geo_node, type: type)
      .execute
  end

  def registries_for_verified_projects(type)
    Geo::ProjectRegistryVerifiedFinder
      .new(current_node: geo_node, type: type)
      .execute
  end

  def registries_for_verification_failed_projects(type)
    Geo::ProjectRegistryVerificationFailedFinder
      .new(current_node: geo_node, type: type)
      .execute
  end

  def registries_for_mismatch_projects(type)
    Geo::ProjectRegistryMismatchFinder
      .new(current_node: geo_node, type: type)
      .execute
  end

  def registries_retrying_verification(type)
    Geo::ProjectRegistryRetryingVerificationFinder
      .new(current_node: geo_node, type: type)
      .execute
  end

  def repository_verification_finder
    @repository_verification_finder ||= Geo::RepositoryVerificationFinder.new
  end
end
