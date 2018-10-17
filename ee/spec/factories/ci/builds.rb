# frozen_string_literal: true
FactoryBot.define do
  factory :ee_ci_build, class: Ci::Build, parent: :ci_build do
    trait :protected_environment_failure do
      failed
      failure_reason { Ci::Build.failure_reasons[:protected_environment_failure] }
    end

    trait :security_reports do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :sast, job: build)
      end
    end
  end
end
