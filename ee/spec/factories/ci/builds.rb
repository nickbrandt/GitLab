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
        name report_type

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
  end
end
