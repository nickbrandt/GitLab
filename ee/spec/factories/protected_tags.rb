# frozen_string_literal: true

FactoryBot.modify do
  factory :protected_tag do
    transient do
      authorize_user_to_create { nil }
      authorize_group_to_create { nil }
    end

    trait :developers_can_create do
      transient do
        default_access_level { false }
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_create do
      transient do
        default_access_level { false }
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::NO_ACCESS)
      end
    end

    trait :maintainers_can_create do
      transient do
        default_access_level { false }
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    after(:build) do |protected_tag, evaluator|
      if evaluator.authorize_user_to_create
        protected_tag.create_access_levels.new(user: evaluator.authorize_user_to_create)
      end

      if evaluator.authorize_group_to_create
        protected_tag.create_access_levels.new(group: evaluator.authorize_group_to_create)
      end
    end
  end
end
