FactoryBot.define do
  factory :identity do
    provider 'ldapmain'
    extern_uid 'my-ldap-id'

    trait :group_saml do
      provider 'group_saml'
      extern_uid { generate(:username) }
      saml_provider
    end
  end
end
