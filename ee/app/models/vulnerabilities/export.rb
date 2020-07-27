# frozen_string_literal: true

module Vulnerabilities
  class Export < ApplicationRecord
    include ::Gitlab::Geo::ReplicableModel

    self.table_name = "vulnerability_exports"

    with_replicator Geo::VulnerabilityExportReplicator

    belongs_to :project
    belongs_to :group
    belongs_to :author, optional: false, class_name: 'User'

    has_one :vulnerability_export_verification_status, class_name: 'Vulnerabilities::ExportVerificationStatus', inverse_of: :vulnerability_export, foreign_key: :vulnerability_export_id

    delegate :verification_retry_at, :verification_retry_at=,
             :verified_at, :verified_at=,
             :verification_checksum, :verification_checksum=,
             :verification_failure, :verification_failure=,
             :verification_retry_count, :verification_retry_count=,
             to: :vulnerability_export_verification_status

    mount_uploader :file, AttachmentUploader

    after_save :update_file_store, if: :saved_change_to_file?

    enum format: {
      csv: 0
    }

    validates :status, presence: true
    validates :format, presence: true
    validates :file, presence: true, if: :finished?
    validate :only_one_exportable

    state_machine :status, initial: :created do
      event :start do
        transition created: :running
      end

      event :finish do
        transition running: :finished
      end

      event :failed do
        transition [:created, :running] => :failed
      end

      event :reset_state do
        transition running: :created
      end

      state :created
      state :running
      state :finished
      state :failed

      before_transition created: :running do |export|
        export.started_at = Time.current
      end

      before_transition any => [:finished, :failed] do |export|
        export.finished_at = Time.current
      end
    end

    def exportable
      project || group || author.security_dashboard
    end

    def exportable=(value)
      case value
      when Project
        make_project_level_export(value)
      when Group
        make_group_level_export(value)
      when InstanceSecurityDashboard
        make_instance_level_export
      else
        raise "Can not assign #{value.class} as exportable"
      end
    end

    def completed?
      finished? || failed?
    end

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end

    def update_file_store
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end

    def vulnerability_export_verification_status
      super.presence || build_vulnerability_export_verification_status
    end

    def local?
      file_store == ObjectStorage::Store::LOCAL
    end

    def self.replicables_for_geo_node
      self.all
    end

    private

    def make_project_level_export(project)
      self.project = project
      self.group = nil
    end

    def make_group_level_export(group)
      self.group = group
      self.project = nil
    end

    def make_instance_level_export
      self.project = self.group = nil
    end

    def only_one_exportable
      errors.add(:base, _('Project & Group can not be assigned at the same time')) if project && group
    end
  end
end
