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

    trait :opened do
      state { :opened }
    end

    trait :resolved do
      state { :resolved }
      resolved_at { Time.current }
    end

    trait :closed do
      state { :closed }
      closed_at { Time.current }
    end

    trait :with_findings do
      after(:build) do |vulnerability|
        vulnerability.findings = build_list(
          :vulnerabilities_occurrence,
          2,
          vulnerability: vulnerability,
          report_type: vulnerability.report_type,
          project: vulnerability.project)
      end
    end

    trait :with_issue_links do
      after(:create) do |vulnerability|
        create_list(:issue, 2).each do |issue|
          create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)
        end
      end
    end
  end
end
