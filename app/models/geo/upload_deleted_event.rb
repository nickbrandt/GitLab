module Geo
  class UploadDeletedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :upload

    validates :upload, :path, :checksum, :model_id, :model_type, presence: true
  end
end
