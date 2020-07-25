# frozen_string_literal: true

class DependencyProxy::Blob < ApplicationRecord
  belongs_to :group

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  mount_uploader :file, DependencyProxy::FileUploader

  after_save :update_file_store, if: :saved_change_to_file?

  def self.total_size
    sum(:size)
  end

  def self.find_or_build(file_name)
    find_or_initialize_by(file_name: file_name)
  end

  def update_file_store
    # The file.object_store is set during `uploader.store!`
    # which happens after object is inserted/updated
    self.update_column(:file_store, file.object_store)
  end
end
