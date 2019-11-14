# frozen_string_literal: true

require 'spec_helper'

describe GroupSaml::SamlProvider::UpdateService do
  subject(:service) { described_class.new(nil, saml_provider, params: params) }

  let(:saml_provider) do
    create :saml_provider, enabled: false, enforced_sso: false, enforced_group_managed_accounts: enforced_group_managed_accounts
  end
  let(:group) { saml_provider.group }

  include_examples 'base SamlProvider service'
end
