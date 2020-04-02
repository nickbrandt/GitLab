# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    belongs_to :project
    belongs_to :locked_by, class_name: 'User'

    validates :project_id, presence: true

    mount_uploader :file, StateUploader

    def update_file_store!
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end

    def file_store
      super || StateUploader.default_store
    end

    def locked?
      self.lock_xid.present?
    end
  end
end
