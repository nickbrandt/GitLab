# frozen_string_literal: true

module Geo
  class FileRegistryRemovalWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    loggable_arguments 0, 2

    def perform(object_type, object_db_id, file_path = nil)
      log_info('Executing Geo::FileRegistryRemovalService', id: object_db_id, type: object_type, file_path: file_path)

      ::Geo::FileRegistryRemovalService.new(object_type, object_db_id, file_path).execute
    end
  end
end
