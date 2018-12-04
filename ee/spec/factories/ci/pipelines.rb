# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_pipeline, class: Ci::Pipeline, parent: :ci_pipeline do
    trait :webide do
      source :webide
      config_source :webide_source
    end
  end
end
