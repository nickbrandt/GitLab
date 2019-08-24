# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding an Upload record
      #   * Returning the necessary response data to send the file back
      #
      class FileUploader < BaseUploader
        def execute
          recorded_file = fetch_resource

          return error('Upload not found') unless recorded_file
          return file_not_found(recorded_file) unless recorded_file.exist?
          return error('Upload not found') unless valid?(recorded_file)

          success(CarrierWave::SanitizedFile.new(recorded_file.absolute_path))
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord

        def fetch_resource
          Upload.find_by(id: object_db_id)
        end

        # rubocop: enable CodeReuse/ActiveRecord

        def valid?(recorded_file)
          matches_requested_model?(recorded_file) &&
            matches_checksum?(recorded_file)
        end

        def matches_requested_model?(recorded_file)
          message[:id] == recorded_file.model_id &&
            message[:type] == recorded_file.model_type
        end

        def matches_checksum?(recorded_file)
          message[:checksum] == Upload.hexdigest(recorded_file.absolute_path)
        end
      end
    end
  end
end
