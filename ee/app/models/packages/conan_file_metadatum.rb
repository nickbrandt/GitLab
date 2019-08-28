# frozen_string_literal: true
class Packages::ConanFileMetadatum < ApplicationRecord
  belongs_to :package_file

  validates :package_file, presence: true

  validates :path,
    presence: true

  validates :recipe,
    presence: true

  validates :revision, presence: true
end
