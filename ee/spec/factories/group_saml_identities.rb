# frozen_string_literal: true
FactoryBot.define do
  factory :group_saml_identity, class: 'Identity', parent: :identity do
    provider { 'group_saml' }
    extern_uid { generate(:username) }
    saml_provider
    user
  end
end
