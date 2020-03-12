# frozen_string_literal: true

class TerraformState < ApplicationRecord
  belongs_to :project

  validates :project_id, presence: true

  after_save :update_file_store, if: :saved_change_to_file?

  mount_uploader :file, TerraformStateUploader

  def update_file_store
    # The file.object_store is set during `uploader.store!`
    # which happens after object is inserted/updated
    self.update_column(:file_store, file.object_store)
  end

  def file_store
    super || TerraformStateUploader.default_store
  end
end
