# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_issue_link, class: Vulnerabilities::IssueLink do
    vulnerability
    issue

    trait :created do
      link_type { :created }
    end

    trait :related do
      link_type { :related }
    end
  end
end
