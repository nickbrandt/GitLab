# frozen_string_literal: true

module Geo
  class FileDownloadDispatchWorker # rubocop:disable Scalability/IdempotentWorker
    class AttachmentJobFinder < JobFinder # rubocop:disable Scalability/IdempotentWorker
      EXCEPT_RESOURCE_IDS_KEY = :except_ids

      def registry_finder
        @registry_finder ||= Geo::AttachmentRegistryFinder.new(current_node_id: Gitlab::Geo.current_node.id)
      end

      def find_unsynced_jobs(batch_size:)
        convert_registry_relation_to_job_args(
          registry_finder.find_never_synced_registries(find_batch_params(batch_size))
        )
      end

      private

      # Why do we need a different `file_type` for each Uploader? Why not just use 'upload'?
      # rubocop: disable CodeReuse/ActiveRecord
      def convert_resource_relation_to_job_args(relation)
        relation.pluck(:id, :uploader)
                .map! { |id, uploader| [uploader.sub(/Uploader\z/, '').underscore, id] }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def convert_registry_relation_to_job_args(relation)
        relation.pluck(:file_type, :file_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
