# frozen_string_literal: true

module Geo
  class FileDownloadDispatchWorker # rubocop:disable Scalability/IdempotentWorker
    class JobArtifactJobFinder < JobFinder # rubocop:disable Scalability/IdempotentWorker
      RESOURCE_ID_KEY = :artifact_id
      EXCEPT_RESOURCE_IDS_KEY = :except_ids
      FILE_SERVICE_OBJECT_TYPE = :job_artifact

      def registry_finder
        @registry_finder ||= Geo::JobArtifactRegistryFinder.new(current_node_id: Gitlab::Geo.current_node.id)
      end

      def find_unsynced_jobs(batch_size:)
        convert_registry_relation_to_job_args(
          registry_finder.find_never_synced_registries(find_batch_params(batch_size))
        )
      end
    end
  end
end
