# frozen_string_literal: true

FactoryBot.define do
  sequence :vulnerability_occurrence_uuid do |n|
    SecureRandom.uuid
  end

  factory :vulnerabilities_occurrence, class: 'Vulnerabilities::Occurrence', aliases: [:vulnerabilities_finding] do
    name { 'Cipher with no integrity' }
    project
    sequence(:uuid) { generate(:vulnerability_occurrence_uuid) }
    project_fingerprint { generate(:project_fingerprint) }
    primary_identifier factory: :vulnerabilities_identifier
    location_fingerprint { '4e5b6966dd100170b4b1ad599c7058cce91b57b4' }
    report_type { :sast }
    severity { :high }
    confidence { :medium }
    scanner factory: :vulnerabilities_scanner
    metadata_version { 'sast:1.0' }
    raw_metadata do
      {
        description: "The cipher does not provide data integrity update 1",
        solution: "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
        location: {
          file: "maven/src/main/java/com/gitlab/security_products/tests/App.java",
          start_line: 29,
          end_line: 29,
          class: "com.gitlab.security_products.tests.App",
          method: "insecureCypher"
        },
        links: [
          {
            name: "Cipher does not check for integrity first?",
            url: "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first"
          }
        ]
      }.to_json
    end

    trait :confirmed do
      after(:create) do |finding|
        create(:vulnerability, :detected, project: finding.project, findings: [finding])
      end
    end

    trait :resolved do
      after(:create) do |finding|
        create(:vulnerability, :resolved, project: finding.project, findings: [finding])
      end
    end

    trait :dismissed do
      after(:create) do |finding|
        create(:vulnerability_feedback,
               :dismissal,
               project: finding.project,
               project_fingerprint: finding.project_fingerprint)
      end
    end

    trait :with_issue_feedback do
      after(:create) do |finding|
        create(:vulnerability_feedback,
               :issue,
               project: finding.project,
               project_fingerprint: finding.project_fingerprint)
      end
    end

    ::Vulnerabilities::Occurrence::REPORT_TYPES.keys.each do |security_report_type|
      trait security_report_type do
        report_type { security_report_type }
      end
    end
  end
end
