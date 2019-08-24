# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding an Upload record
      #   * Requesting and downloading the Upload's file from the primary
      #   * Returning a detailed Result
      #
      class FileDownloader < BaseDownloader
        # Executes the actual file download
        #
        # Subclasses should return the number of bytes downloaded,
        # or nil or -1 if a failure occurred.
        def execute
          upload = find_resource
          return fail_before_transfer unless upload.present?
          return missing_on_primary if upload.model.nil?

          transfer = ::Gitlab::Geo::Replication::FileTransfer.new(object_type.to_sym, upload)
          Result.from_transfer_result(transfer.download_from_primary)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord

        def find_resource
          Upload.find_by(id: object_db_id)
        end

        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
