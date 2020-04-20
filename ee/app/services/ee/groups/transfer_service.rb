# frozen_string_literal: true

module EE
  module Groups
    module TransferService
      extend ::Gitlab::Utils::Override

      def localized_ee_error_messages
        {
          group_contains_npm_packages: s_('TransferGroup|Group contains projects with NPM packages.')
        }.freeze
      end

      def update_group_attributes
        ::Epic.nullify_lost_group_parents(group.self_and_descendants, lost_groups)

        super
      end

      private

      override :ensure_allowed_transfer
      def ensure_allowed_transfer
        super
        return unless group.packages_feature_available?

        npm_packages = Packages::GroupPackagesFinder.new(current_user, group, package_type: :npm).execute
        if different_root_ancestor? && npm_packages.exists?
          raise_ee_transfer_error(:group_contains_npm_packages)
        end
      end

      override :post_update_hooks
      def post_update_hooks(updated_project_ids)
        ::Project.id_in(updated_project_ids).find_each do |project|
          project.maintain_elasticsearch_update if project.maintaining_elasticsearch?
        end
      end

      def raise_ee_transfer_error(message)
        raise ::Groups::TransferService::TransferError, localized_ee_error_messages[message]
      end

      def different_root_ancestor?
        group.root_ancestor != new_parent_group&.root_ancestor
      end

      def lost_groups
        ancestors = group.ancestors

        if ancestors.include?(new_parent_group)
          group.ancestors_upto(new_parent_group)
        else
          ancestors
        end
      end
    end
  end
end
