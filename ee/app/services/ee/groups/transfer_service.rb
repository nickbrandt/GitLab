# frozen_string_literal: true

module EE
  module Groups
    module TransferService
      extend ::Gitlab::Utils::Override

      EE_ERROR_MESSAGES = {
        group_contains_npm_packages: s_('TransferGroup|Group contains projects with NPM packages.')
      }.freeze

      private

      override :ensure_allowed_transfer
      def ensure_allowed_transfer
        super
        return unless group.packages_feature_available?

        npm_packages = Packages::GroupPackagesFinder.new(current_user, group, package_type: :npm).execute
        if !new_parent_group_has_same_root_ancestor? && npm_packages.exists?
          raise_ee_transfer_error(:group_contains_npm_packages)
        end
      end

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

      def raise_ee_transfer_error(message)
        raise ::Groups::TransferService::TransferError, EE_ERROR_MESSAGES[message]
      end

      def new_parent_group_has_same_root_ancestor?
        group.root_ancestor == new_parent_group.root_ancestor
      end
    end
  end
end
