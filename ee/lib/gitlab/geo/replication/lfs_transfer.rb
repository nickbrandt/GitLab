# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Requesting an LfsObject file from the primary
      #   * Saving it in the right place on successful download
      #   * Returning a detailed Result object
      class LfsTransfer < BaseTransfer
        def initialize(lfs_object)
          super(
            file_type: :lfs,
            file_id: lfs_object.id,
            filename: lfs_object.file.path,
            expected_checksum: lfs_object.oid,
            request_data: lfs_request_data(lfs_object)
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
end
