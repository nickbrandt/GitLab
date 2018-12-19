# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_license_management_report, class: ::Gitlab::Ci::Reports::LicenseManagement::Report do
    trait :report_1 do
      after(:build) do |report, evaluator|
        report.add_dependency('MIT', 'Library1')
        report.add_dependency('WTFPL', 'Library2')
      end
    end

    trait :report_2 do
      after(:build) do |report, evaluator|
        report.add_dependency('MIT', 'Library1')
        report.add_dependency('Apache 2.0', 'Library3')
      end
    end
  end
end
