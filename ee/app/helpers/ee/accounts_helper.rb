# frozen_string_literal: true

module EE
  module AccountsHelper
    def group_saml_metadata_enabled?(group)
      ::Feature.enabled?(:group_saml_metadata_available, group)
    end
  end
end
