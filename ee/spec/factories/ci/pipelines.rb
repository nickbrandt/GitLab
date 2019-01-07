# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_pipeline, class: Ci::Pipeline, parent: :ci_pipeline do
    trait :webide do
      source :webide
      config_source :webide_source
    end

    trait :with_license_management_report do
      status :success

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :license_management, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_license_management_feature_branch do
      status :success

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :license_management_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_license_management_report do
      status :success

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_license_management_report, pipeline: pipeline, project: pipeline.project)
      end
    end
  end
end
