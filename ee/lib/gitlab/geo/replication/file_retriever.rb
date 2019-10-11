# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding an Upload record
      #   * Returning the necessary response data to send the file back
      #
      class FileRetriever < BaseRetriever
        def execute
          return error('Upload not found') unless recorded_file
          return file_not_found(recorded_file) unless recorded_file.exist?
          return error('Upload not found') unless valid?

          success(recorded_file.retrieve_uploader)
        end

        private

        def recorded_file
          strong_memoize(:recorded_file) do
            Upload.find_by_id(object_db_id)
          end
        end

        def valid?
          matches_requested_model? && matches_checksum?
        end

        def matches_requested_model?
          message[:id] == recorded_file.model_id &&
            message[:type] == recorded_file.model_type
        end

        def matches_checksum?
          # Remove this when we implement checksums for files on the Object Storage
          return true unless recorded_file.local?

          message[:checksum] == Upload.hexdigest(recorded_file.absolute_path)
        end
      end
    end
  end
end
