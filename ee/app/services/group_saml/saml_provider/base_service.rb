# frozen_string_literal: true

module GroupSaml
  module SamlProvider
    module BaseService
      extend FastGettext::Translation

      attr_reader :saml_provider, :params, :current_user

      delegate :group, to: :saml_provider

      def initialize(current_user, saml_provider, params:)
        @saml_provider = saml_provider
        @current_user = current_user
        @params = params
      end

      def execute
        ::SamlProvider.transaction do
          group_managed_accounts_was_enforced = saml_provider.enforced_group_managed_accounts?

          updated = saml_provider.update(params)

          if updated && saml_provider.enforced_group_managed_accounts? && !group_managed_accounts_was_enforced
            cleanup_members!
          end
        end
      end

      private

      def cleanup_members!
        return if GroupManagedAccounts::CleanUpMembersService.new(current_user, group).execute

        saml_provider.errors.add(:base, _("Can't remove group members without group managed account"))
        raise ActiveRecord::Rollback
      end
    end
  end
end
