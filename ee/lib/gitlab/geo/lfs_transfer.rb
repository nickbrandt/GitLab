# frozen_string_literal: true

module Gitlab
  module Geo
    # This class is responsible for:
    #   * Requesting an LfsObject file from the primary
    #   * Saving it in the right place on successful download
    #   * Returning a detailed Result object
    class LfsTransfer < Transfer
      def initialize(lfs_object)
        super(
          :lfs,
          lfs_object.id,
          lfs_object.file.path,
          lfs_object.oid,
          lfs_request_data(lfs_object)
        )
      end

      private

      def lfs_request_data(lfs_object)
        {
          checksum: lfs_object.oid,
          file_type: :lfs,
          file_id: lfs_object.id
        }
      end
    end
  end
end
