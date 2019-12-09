# frozen_string_literal: true

module EE
  module Groups
    module TransferService
      extend ::Gitlab::Utils::Override

      private

      override :post_update_hooks
      # rubocop: disable CodeReuse/ActiveRecord
      def post_update_hooks(updated_project_ids)
        ::Project.where(id: updated_project_ids).find_each do |project|
          # TODO: Refactor out this duplication per https://gitlab.com/gitlab-org/gitlab/issues/38232
          if ::Gitlab::CurrentSettings.elasticsearch_indexing? && project.searchable?
            ElasticIndexerWorker.perform_async(
              :update,
              project.class.to_s,
              project.id,
              project.es_id,
              changed_fields: ['visibility_level']
            )
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
