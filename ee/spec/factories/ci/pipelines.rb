# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_pipeline, class: Ci::Pipeline, parent: :ci_pipeline do
    trait :webide do
      source { :webide }
      config_source { :webide_source }
    end

    %i[license_management dependency_list dependency_scanning sast dast container_scanning].each do |report_type|
      trait "with_#{report_type}_report".to_sym do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ee_ci_build, report_type, :success, pipeline: pipeline, project: pipeline.project)
        end
      end
    end

    trait :with_container_scanning_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :container_scanning_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_container_scanning_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_container_scanning_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_dependency_scanning_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :dependency_scanning_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_dependency_scanning_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_dependency_scanning_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_sast_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :sast_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_dast_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :dast_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_license_management_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :license_management_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_license_management_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_license_management_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_metrics_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :metrics, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_metrics_alternate_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :metrics_alternate, pipeline: pipeline, project: pipeline.project)
      end
    end
  end
end
