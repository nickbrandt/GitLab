# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_job_artifact, class: ::Ci::JobArtifact, parent: :ci_job_artifact do
    trait :sast do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/reports/security/sast.json'), 'application/json')
      end
    end

    trait :sast_with_corrupted_data do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/reports/security/sast_with_corrupted_data.json'), 'application/json')
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
  end
end
