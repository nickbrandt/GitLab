# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability do
    project
    author
    title { generate(:title) }
    title_html { "<h2>#{title}</h2>" }
    severity { :high }
    confidence { :medium }
    report_type { :sast }

    trait :detected do
      state { Vulnerability.states[:detected] }
    end

    trait :resolved do
      state { Vulnerability.states[:resolved] }
      resolved_at { Time.current }
    end

    trait :dismissed do
      state { Vulnerability.states[:dismissed] }
      dismissed_at { Time.current }
    end

    trait :confirmed do
      state { Vulnerability.states[:confirmed] }
      confirmed_at { Time.current }
    end

    trait :critical_severity do
      severity { :critical }
    end

    trait :high_severity do
      severity { :high }
    end

    trait :medium_severity do
      severity { :medium }
    end

    trait :low_severity do
      severity { :low }
    end

    ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.each do |severity_level|
      trait severity_level do
        severity { severity_level }
      end
    end

    ::Vulnerabilities::Occurrence::REPORT_TYPES.keys.each do |report_type|
      trait report_type do
        report_type { report_type }
      end
    end

    trait :with_findings do
      after(:build) do |vulnerability|
        occurrences_with_solution = build_list(
          :vulnerabilities_occurrence,
          2,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project)
        occurrences_with_remediation = build_list(
          :vulnerabilities_occurrence,
          2,
          :with_remediation,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project)
        vulnerability.findings = occurrences_with_solution + occurrences_with_remediation
      end
    end

    trait :with_issue_links do
      after(:create) do |vulnerability|
        create_list(:issue, 2, project: vulnerability.project).each do |issue|
          create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)
        end
      end
    end
  end
end
