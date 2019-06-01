# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_pipeline, class: Ci::Pipeline, parent: :ci_pipeline do
    trait :webide do
      source :webide
      config_source :webide_source
    end

    %i[sast codequality dependency_scanning container_scanning dast performance license_management].each do |report_type|
      trait "with_#{report_type}_report".to_sym do
        status :success

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ee_ci_build, report_type, pipeline: pipeline, project: pipeline.project)
        end
      end
    end

    trait :with_dependency_list_report do
      status :success

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :dependency_list, pipeline: pipeline, project: pipeline.project)
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

    trait :with_metrics_report do
      status :success

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :metrics, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_metrics_alternate_report do
      status :success

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :metrics_alternate, pipeline: pipeline, project: pipeline.project)
      end
    end
  end
end
