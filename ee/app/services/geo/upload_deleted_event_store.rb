module Geo
  class UploadDeletedEventStore < EventStore
    self.event_type = :upload_deleted_event

    attr_reader :upload

    def initialize(upload)
      @upload = upload
    end

    private

    def build_event
      Geo::UploadDeletedEvent.new(
        upload: upload,
        file_path: relative_upload_path,
        checksum: upload.checksum,
        model_id: upload.model_id,
        model_type: upload.model_type,
        uploader: upload.uploader
      )
    end

    # This is called by ProjectLogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::ProjectLogHelpers
    def base_log_data(message)
      {
        class: self.class.name,
        upload_id: upload.id,
        file_path: relative_upload_path,
        model_id: upload.model_id,
        model_type: upload.model_type,
        uploader: upload.uploader,
        message: message
      }
    end

    # store the actual relative path to the file, so we have a chance of locating
    # the file on the secondary if we want.  upload path is determined by the
    # model that created it, so grab that now because the model is most likely being
    # deleted as well
    def relative_upload_path
      upload.absolute_path.sub("#{CarrierWave.root}/", '')
    end
  end
end
