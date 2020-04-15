# frozen_string_literal: true

module Geo
  class PackageFileReplicator < Gitlab::Geo::Replicator
    include ::Geo::BlobReplicatorStrategy

    def carrierwave_uploader
      model_record.file
    end

    def self.model
      ::Packages::PackageFile
    end

    def self.model_foreign_key
      :package_file_id
    end
  end
end
