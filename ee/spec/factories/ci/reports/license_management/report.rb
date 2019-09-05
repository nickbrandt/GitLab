# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_license_management_report, class: ::Gitlab::Ci::Reports::LicenseManagement::Report do
    trait :report_1 do
      after(:build) do |report, evaluator|
        report.add_dependency('MIT', 1, 'https://opensource.org/licenses/mit', 'Library1')
        report.add_dependency('WTFPL', 1, 'https://opensource.org/licenses/wtfpl', 'Library2')
      end
    end

    trait :report_2 do
      after(:build) do |report, evaluator|
        report.add_dependency('MIT', 1, 'https://opensource.org/licenses/mit', 'Library1')
        report.add_dependency('Apache 2.0', 1, 'https://opensource.org/licenses/apache', 'Library3')
      end
    end

    trait :mit do
      after(:build) do |report, evaluator|
        report.add_dependency('MIT', 1, 'https://opensource.org/licenses/mit', 'rails')
      end
    end
  end
end
