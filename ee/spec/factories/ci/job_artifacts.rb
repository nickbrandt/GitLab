# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_job_artifact, class: ::Ci::JobArtifact, parent: :ci_job_artifact do
    trait :sast do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/master/gl-sast-report.json'), 'text/plain')
      end
    end

    trait :sast_deprecated do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/deprecated/gl-sast-report.json'), 'text/plain')
      end
    end

    trait :sast_with_corrupted_data do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :license_management do
      file_type :license_management
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/master/gl-license-management-report.json'), 'application/json')
      end
    end

    trait :license_management_feature_branch do
      file_type :license_management
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/feature-branch/gl-license-management-report.json'), 'application/json')
      end
    end

    trait :corrupted_license_management_report do
      file_type :license_management
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :performance do
      file_format :raw
      file_type :performance

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :license_management do
      file_format :raw
      file_type :license_management

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :dependency_scanning do
      file_format :raw
      file_type :dependency_scanning

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/master/gl-dependency-scanning-report.json'), 'text/plain')
      end
    end

    trait :dependency_scanning_deprecated do
      file_format :raw
      file_type :dependency_scanning

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/deprecated/gl-dependency-scanning-report.json'), 'text/plain')
      end
    end

    trait :container_scanning do
      file_format :raw
      file_type :container_scanning

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/master/gl-container-scanning-report.json'), 'text/plain')
      end
    end

    trait :dast do
      file_format :raw
      file_type :dast

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/security-reports/master/gl-dast-report.json'), 'text/plain')
      end
    end
  end
end
