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

      def raise_ee_transfer_error(message)
        raise ::Groups::TransferService::TransferError, EE_ERROR_MESSAGES[message]
      end

      def new_parent_group_has_same_root_ancestor?
        group.root_ancestor == new_parent_group.root_ancestor
      end
    end
  end
end
