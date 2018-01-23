module Geo
  class UploadDeletedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :upload

    validates :upload, :file_path, :checksum, :model_id, :model_type,
              :uploader, presence: true

    def upload_type
      uploader&.sub(/Uploader\z/, '')&.underscore
    end
  end
end
