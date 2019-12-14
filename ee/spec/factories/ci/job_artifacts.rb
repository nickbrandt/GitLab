# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_job_artifact, class: ::Ci::JobArtifact, parent: :ci_job_artifact do
    trait :sast do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-sast-report.json'), 'application/json')
      end
    end

    trait :dast do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report.json'), 'application/json')
      end
    end

    trait :dast_feature_branch do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-dast-report.json'), 'application/json')
      end
    end

    trait :dast_with_corrupted_data do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :dast_deprecated do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/deprecated/gl-dast-report.json'), 'application/json')
      end
    end

    trait :dast_multiple_sites do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-multiple-sites.json'), 'application/json')
      end
    end

    trait :low_severity_dast_report do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-low-severity.json'), 'application/json')
      end
    end

    trait :sast_feature_branch do
      file_format { :raw }
      file_type { :sast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-sast-report.json'), 'application/json')
      end
    end

    trait :sast_deprecated do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/deprecated/gl-sast-report.json'), 'application/json')
      end
    end

    trait :sast_with_corrupted_data do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :license_management do
      file_type { :license_management }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-license-management-report.json'), 'application/json')
      end
    end

    trait :license_management_feature_branch do
      file_type { :license_management }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-license-management-report.json'), 'application/json')
      end
    end

    trait :corrupted_license_management_report do
      file_type { :license_management }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :performance do
      file_format { :raw }
      file_type { :performance }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :license_management do
      file_format { :raw }
      file_type { :license_management }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :dependency_scanning do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :dependency_scanning_remediation do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/remediations/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :dependency_scanning_deprecated do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/deprecated/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :dependency_scanning_feature_branch do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :corrupted_dependency_scanning_report do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :container_scanning do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-container-scanning-report.json'), 'application/json')
      end
    end

    trait :container_scanning_feature_branch do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-container-scanning-report.json'), 'application/json')
      end
    end

    trait :corrupted_container_scanning_report do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :deprecated_container_scanning_report do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/deprecated/gl-container-scanning-report.json'), 'text/plain')
      end
    end

    trait :metrics do
      file_format { :gzip }
      file_type { :metrics }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/metrics.txt.gz'), 'application/x-gzip')
      end
    end

    trait :metrics_alternate do
      file_format { :gzip }
      file_type { :metrics }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/alternate_metrics.txt.gz'), 'application/x-gzip')
      end
    end

    trait :dependency_list do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/dependency_list/gl-dependency-scanning-report.json'), 'application/json')
      end
    end
  end
end
