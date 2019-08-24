# frozen_string_literal: true

module Geo
  # This class is responsible for:
  #   * Handling file requests from the secondary over the API
  #   * Returning the necessary response data to send the file back
  class FileUploadService < BaseFileService
    attr_reader :auth_header
    include ::Gitlab::Utils::StrongMemoize

    def initialize(params, auth_header)
      super(params[:type], params[:id])
      @auth_header = auth_header
    end

    # Returns { code: :ok, file: CarrierWave File object } upon success
    def execute
      return unless decoded_authorization.present? && jwt_scope_valid?

      uploader.execute
    end

    def uploader
      uploader_klass.new(object_db_id, decoded_authorization)
    end

    private

    def jwt_scope_valid?
      (decoded_authorization[:file_type] == object_type.to_s) && (decoded_authorization[:file_id] == object_db_id)
    end

    def decoded_authorization
      strong_memoize(:decoded_authorization) do
        ::Gitlab::Geo::JwtRequestDecoder.new(auth_header).decode
      end
    end

    def uploader_klass
      return Gitlab::Geo::Replication::FileUploader if user_upload?
      return Gitlab::Geo::Replication::JobArtifactUploader if job_artifact?
      return Gitlab::Geo::Replication::LfsUploader if lfs?

      error_message = "Cannot find a Gitlab::Geo Uploader for object_type = '#{object_type}'"

      log_error(error_message)
      raise NotImplementedError, error_message
    end
  end
end
