# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      class BaseDownloader
        attr_reader :object_type, :object_db_id

        def initialize(object_type, object_db_id)
          @object_type = object_type
          @object_db_id = object_db_id
        end

        class Result
          attr_reader :success, :bytes_downloaded, :primary_missing_file, :failed_before_transfer

          def self.from_transfer_result(transfer_result)
            Result.new(success: transfer_result.success,
                       primary_missing_file: transfer_result.primary_missing_file,
                       bytes_downloaded: transfer_result.bytes_downloaded)
          end

          def initialize(success:, bytes_downloaded:, primary_missing_file: false, failed_before_transfer: false)
            @success = success
            @bytes_downloaded = bytes_downloaded
            @primary_missing_file = primary_missing_file
            @failed_before_transfer = failed_before_transfer
          end
        end

        private

        def fail_before_transfer
          Result.new(success: false, bytes_downloaded: 0, failed_before_transfer: true)
        end

        def missing_on_primary
          Result.new(success: true, bytes_downloaded: 0, primary_missing_file: true)
        end
      end
    end
  end
end
