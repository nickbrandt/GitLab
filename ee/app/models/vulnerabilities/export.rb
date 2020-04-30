# frozen_string_literal: true

module Vulnerabilities
  class Export < ApplicationRecord
    self.table_name = "vulnerability_exports"

    belongs_to :project
    belongs_to :group
    belongs_to :author, optional: false, class_name: 'User'

    mount_uploader :file, AttachmentUploader

    after_save :update_file_store, if: :saved_change_to_file?

    enum format: {
      csv: 0
    }

    validates :status, presence: true
    validates :format, presence: true
    validates :file, presence: true, if: :finished?

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

      state :created
      state :running
      state :finished
      state :failed

      before_transition created: :running do |export|
        export.started_at = Time.now
      end

      before_transition any => [:finished, :failed] do |export|
        export.finished_at = Time.now
      end
    end

    def exportable
      project || author.security_dashboard
    end

    def exportable=(value)
      case value
      when Project
        self.project = value
      when InstanceSecurityDashboard
        self.project = nil
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
  end
end
