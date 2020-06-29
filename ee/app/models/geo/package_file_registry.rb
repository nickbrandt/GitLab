# frozen_string_literal: true

class Geo::PackageFileRegistry < Geo::BaseRegistry
  include ::Geo::ReplicableRegistry
  include ShaAttribute

  MODEL_CLASS = ::Packages::PackageFile
  MODEL_FOREIGN_KEY = :package_file_id

  belongs_to :package_file, class_name: 'Packages::PackageFile'

  sha_attribute :verification_checksum
  sha_attribute :verification_checksum_mismatched

  def self.has_create_events?
    true
  end

  def self.delete_for_model_ids(package_file_ids)
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/222635
    []
  end
end
