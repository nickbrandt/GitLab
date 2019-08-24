# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding a LfsObject record
      #   * Requesting and downloading the LfsObject's file from the primary
      #   * Returning a detailed Result
      #
      class LfsDownloader < BaseDownloader
        def execute
          lfs_object = find_resource
          return fail_before_transfer unless lfs_object.present?

          transfer = ::Gitlab::Geo::Replication::LfsTransfer.new(lfs_object)
          Result.from_transfer_result(transfer.download_from_primary)
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord

        def find_resource
          LfsObject.find_by(id: object_db_id)
        end

        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
