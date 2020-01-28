# frozen_string_literal: true

FactoryBot.modify do
  factory :user do
    trait :auditor do
      auditor { true }
    end

    trait :group_managed do
      association :managing_group, factory: :group
    end
  end

  factory :omniauth_user do
    transient do
      saml_provider { nil }
    end
  end
end

FactoryBot.define do
  factory :auditor, parent: :user, traits: [:auditor]
  factory :external_user, parent: :user, traits: [:external]
end
