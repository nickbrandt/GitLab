# frozen_string_literal: true

FactoryBot.define do
  factory :merge_train do
    target_branch { 'master' }
    target_project factory: :project
    merge_request
    user
    pipeline factory: :ci_pipeline

    trait :created do
      status { :created }
    end

    trait :merged do
      status { :merged }
    end

    trait :stale do
      status { :stale }
    end

    trait :fresh do
      status { :fresh }
    end
  end
end
