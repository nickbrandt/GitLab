# frozen_string_literal: true
FactoryBot.define do
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
