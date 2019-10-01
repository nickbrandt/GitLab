# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_subscription do
    namespace
    association :hosted_plan, factory: :gold_plan
    seats { 10 }
    start_date { Date.today }
    end_date { Date.today.advance(years: 1) }
    trial { false }

    trait :free do
      hosted_plan_id { nil }
    end

    trait :early_adopter do
      association :hosted_plan, factory: :early_adopter_plan
    end

    trait :bronze do
      association :hosted_plan, factory: :bronze_plan
    end

    trait :silver do
      association :hosted_plan, factory: :silver_plan
    end

    trait :gold do
      association :hosted_plan, factory: :gold_plan
    end
  end
end
