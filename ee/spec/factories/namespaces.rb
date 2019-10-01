# frozen_string_literal: true

FactoryBot.modify do
  factory :namespace do
    transient do
      plan { nil }
    end

    before(:create) do |namespace, evaluator|
      if evaluator.plan.present?
        namespace.plan = create(evaluator.plan)
      end
    end

    trait :with_build_minutes do
      namespace_statistics factory: :namespace_statistics, shared_runners_seconds: 400.minutes.to_i
    end

    trait :with_build_minutes_limit do
      shared_runners_minutes_limit { 500 }
    end

    trait :with_not_used_build_minutes_limit do
      namespace_statistics factory: :namespace_statistics, shared_runners_seconds: 300.minutes.to_i
      shared_runners_minutes_limit { 500 }
    end

    trait :with_used_build_minutes_limit do
      namespace_statistics factory: :namespace_statistics, shared_runners_seconds: 1000.minutes.to_i
      shared_runners_minutes_limit { 500 }
    end
  end
end
