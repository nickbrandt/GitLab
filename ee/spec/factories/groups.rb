# frozen_string_literal: true

FactoryBot.define do
  factory :group_with_members, parent: :group do
    after(:create) do |group, evaluator|
      group.add_developer(create :user)
    end
  end

  factory :group_with_ldap, parent: :group do
    transient do
      cn { 'group1' }
      group_access { Gitlab::Access::GUEST }
      provider { 'ldapmain' }
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

  factory :group_with_deletion_schedule, parent: :group do
    transient do
      deleting_user { create(:user) }
      marked_for_deletion_on { nil }
    end

    after(:create) do |group, evaluator|
      create(:group_deletion_schedule,
        group: group,
        deleting_user: evaluator.deleting_user,
        marked_for_deletion_on: evaluator.marked_for_deletion_on
      )
    end
  end
end
