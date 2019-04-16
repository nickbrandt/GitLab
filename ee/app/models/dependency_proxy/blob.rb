# frozen_string_literal: true

class DependencyProxy::Blob < ApplicationRecord
  belongs_to :group

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  mount_uploader :file, DependencyProxy::FileUploader

  def self.total_size
    sum(:size)
  end

  def self.find_or_build(file_name)
    find_or_initialize_by(file_name: file_name)
  end
end
