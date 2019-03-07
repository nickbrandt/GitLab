# frozen_string_literal: true

FactoryBot.modify do
  factory :merge_request do
    trait :with_approver do
      after :create do |merge_request|
        create :approver, target: merge_request
      end
    end

    transient do
      approval_groups []
      approval_users []
    end

    after :create do |merge_request, evaluator|
      next if evaluator.approval_users.blank? && evaluator.approval_groups.blank?

      rule = merge_request.approval_rules.first_or_create(attributes_for(:approval_merge_request_rule))
      rule.users = evaluator.approval_users if evaluator.approval_users.present?
      rule.groups = evaluator.approval_groups if evaluator.approval_groups.present?
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
