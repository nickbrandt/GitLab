# frozen_string_literal: true

FactoryBot.modify do
  factory :group do
    project_creation_level ::EE::Gitlab::Access::MAINTAINER_PROJECT_ACCESS
  end
end

FactoryBot.define do
  factory :group_with_members, parent: :group do
    after(:create) do |group, evaluator|
      group.add_developer(create :user)
    end
  end

  factory :group_with_ldap, parent: :group do
    transient do
      cn 'group1'
      group_access Gitlab::Access::GUEST
      provider 'ldapmain'
    end

    factory :group_with_ldap_group_link do
      after(:create) do |group, evaluator|
        group.ldap_group_links << create(
          :ldap_group_link,
            cn: evaluator.cn,
            group_access: evaluator.group_access,
            provider: evaluator.provider
        )
      end
    end

    factory :group_with_ldap_group_filter_link do
      after(:create) do |group, evaluator|
        group.ldap_group_links << create(
          :ldap_group_link,
            filter: '(a=b)',
            cn: nil,
            group_access: evaluator.group_access,
            provider: evaluator.provider
        )
      end
    end
  end
end
