# frozen_string_literal: true

FactoryBot.modify do
  factory :merge_request do
    trait :with_approver do
      after :create do |merge_request|
        create :approver, target: merge_request
      end
    end
  end
end

FactoryBot.define do
  factory :merge_request_with_approver, parent: :merge_request, traits: [:with_approver]

  factory :ee_merge_request, parent: :merge_request do
    trait :with_license_management_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_license_management_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end
  end
end
