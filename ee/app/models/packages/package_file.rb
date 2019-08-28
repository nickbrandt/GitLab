# frozen_string_literal: true
class Packages::PackageFile < ApplicationRecord
  include UpdateProjectStatistics

  delegate :project, :project_id, to: :package

  update_project_statistics project_statistics_name: :packages_size

  belongs_to :package
  has_one :conan_file_metadatum, inverse_of: :package

  accepts_nested_attributes_for :conan_file_metadatum

  validates :package, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  scope :recent, -> { order(id: :desc) }
  scope :with_files_stored_locally, -> { where(file_store: ::Packages::PackageFileUploader::Store::LOCAL) }

  mount_uploader :file, Packages::PackageFileUploader

  after_save :update_file_store, if: :saved_change_to_file?

  def update_file_store
    # The file.object_store is set during `uploader.store!`
    # which happens after object is inserted/updated
    self.update_column(:file_store, file.object_store)
  end

  def log_geo_deleted_event
    # Keep empty for now. Should be addressed in future
    # by https://gitlab.com/gitlab-org/gitlab-ee/issues/7891
  end
end
