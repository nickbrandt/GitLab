# frozen_string_literal: true
FactoryBot.define do
  factory :ee_ci_build, class: Ci::Build, parent: :ci_build do
    trait :protected_environment_failure do
      failed
      failure_reason { Ci::Build.failure_reasons[:protected_environment_failure] }
    end

    %i[sast codequality dependency_scanning container_scanning dast performance license_management].each do |report_type|
      trait "legacy_#{report_type}".to_sym do
        success
        artifacts
        name { report_type }

        options do
          {
            artifacts: {
              paths: [Ci::JobArtifact::DEFAULT_FILE_NAMES[report_type]]
            }
          }
        end
      end

      trait report_type do
        after(:build) do |build|
          build.job_artifacts << build(:ee_ci_job_artifact, report_type, job: build)
        end
      end
    end

    trait :dependency_list do
      name { :dependency_scanning }

      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :dependency_list, job: build)
      end
    end

    trait :metrics do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :metrics, job: build)
      end
    end

    trait :metrics_alternate do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :metrics_alternate, job: build)
      end
    end

    trait :sast_feature_branch do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :sast_feature_branch, job: build)
      end
    end

    trait :dast_feature_branch do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :dast_feature_branch, job: build)
      end
    end

    trait :container_scanning_feature_branch do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :container_scanning_feature_branch, job: build)
      end
    end

    trait :corrupted_container_scanning_report do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :corrupted_container_scanning_report, job: build)
      end
    end

    trait :deprecated_container_scanning_report do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :deprecated_container_scanning_report, job: build)
      end
    end

    trait :dependency_scanning_feature_branch do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :dependency_scanning_feature_branch, job: build)
      end
    end

    trait :dependency_scanning_report do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :dependency_scanning_report, job: build)
      end
    end

    trait :corrupted_dependency_scanning_report do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :corrupted_dependency_scanning_report, job: build)
      end
    end

    trait :license_management_feature_branch do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :license_management_feature_branch, job: build)
      end
    end

    trait :corrupted_license_management_report do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :corrupted_license_management_report, job: build)
      end
    end

    trait :low_severity_dast_report do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :low_severity_dast_report, job: build)
      end
    end
  end
end
