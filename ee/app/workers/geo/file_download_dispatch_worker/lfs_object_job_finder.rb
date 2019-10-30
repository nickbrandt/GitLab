# frozen_string_literal: true

module Geo
  class FileDownloadDispatchWorker
    class LfsObjectJobFinder < JobFinder
      RESOURCE_ID_KEY = :lfs_object_id
      EXCEPT_RESOURCE_IDS_KEY = :except_ids
      FILE_SERVICE_OBJECT_TYPE = :lfs

      def registry_finder
        @registry_finder ||= Geo::LfsObjectRegistryFinder.new(current_node_id: Gitlab::Geo.current_node.id)
      end
    end
  end
end
