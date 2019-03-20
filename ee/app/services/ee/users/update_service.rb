# frozen_string_literal: true

module EE
  module Users
    module UpdateService
      extend ::Gitlab::Utils::Override
      include EE::Audit::Changes # rubocop: disable Cop/InjectEnterpriseEditionModule

      private

      def notify_success(user_exists)
        notify_new_user(@user, nil) unless user_exists # rubocop:disable Gitlab/ModuleWithInstanceVariables

        audit_changes(:email, as: 'email address')
        audit_changes(:encrypted_password, as: 'password', skip_changes: true)

        success
      end

      def model
        @user
      end

      override :assign_attributes
      def assign_attributes
        params.reject! { |key, _| SamlProvider::USER_ATTRIBUTES_LOCKED_FOR_MANAGED_ACCOUNTS.include?(key.to_sym) } if model.group_managed_account?
        super
      end
    end
  end
end
