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
        include ::Gitlab::Utils::StrongMemoize

        def execute
          check_result = check_preconditions
          return check_result if check_result

          result = if local_store?
                     transfer.download_from_primary
                   else
                     transfer.stream_from_primary_to_object_storage
                   end

          Result.from_transfer_result(result)
        end

        private

        def local_store?
          resource.local_store?
        end

        def resource
          strong_memoize(:resource) { LfsObject.find_by_id(object_db_id) }
        end

        def transfer
          strong_memoize(:transfer) { ::Gitlab::Geo::Replication::LfsTransfer.new(resource) }
        end

        def check_preconditions
          unless resource.present?
            return fail_before_transfer(reason: "Skipping transfer as the #{object_type.to_s.capitalize} (ID = #{object_db_id}) could not be found")
          end

          unless local_store?
            unless sync_object_storage_enabled?
              return fail_before_transfer(reason: "Skipping transfer as this secondary node is not allowed to replicate content on Object Storage")
            end

            unless object_store_enabled?
              return fail_before_transfer(reason: "Skipping transfer as this secondary node is not configured to store #{object_type.to_s.capitalize} on Object Storage")
            end
          end

          nil
        end

        def object_store_enabled?
          LfsObjectUploader.object_store_enabled?
        end

        def sync_object_storage_enabled?
          Gitlab::Geo.current_node.sync_object_storage
        end
      end
    end
  end
end
