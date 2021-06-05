# frozen_string_literal: true

class ImportExportUpload < ApplicationRecord
  include WithUploads
  include ObjectStorage::BackgroundMove

  belongs_to :project
  belongs_to :group

  # These hold the project Import/Export archives (.tar.gz files)
  mount_uploader :import_file, ImportExportUploader
  mount_uploader :export_file, ImportExportUploader

  # This causes CarrierWave v1 and v3 (but not v2) to upload the file to
  # object storage *after* the database entry has been committed to the
  # database. This avoids idling in a transaction.
  skip_callback :save, :after, :store_export_file!
  set_callback :commit, :after, :store_export_file!

  scope :updated_before, ->(date) { where('updated_at < ?', date) }
  scope :with_export_file, -> { where.not(export_file: nil) }

  def retrieve_upload(_identifier, paths)
    Upload.find_by(model: self, path: paths)
  end
end
