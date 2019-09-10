# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding an LfsObject record
      #   * Returning the necessary response data to send the file back
      #
      class LfsRetriever < BaseRetriever
        def execute
          lfs_object = fetch_resource

          return error('LFS object not found') unless lfs_object
          return error('LFS object not found') if message[:checksum] != lfs_object.oid

          unless lfs_object.file.present? && lfs_object.file.exists?
            log_error("Could not upload LFS object because it does not have a file", id: lfs_object.id)

            return file_not_found(lfs_object)
          end

          success(lfs_object.file)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord

        def fetch_resource
          LfsObject.find_by(id: object_db_id)
        end

        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
