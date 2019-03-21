# frozen_string_literal: true

module EE
  module IdentityProviderPolicy
    extend ActiveSupport::Concern

    prepended do
      desc "User account is managed by group SAML"
      condition(:group_managed_account, scope: :user) { @user.group_managed_account? }

      rule { group_managed_account }.prevent_all
    end
  end
end
