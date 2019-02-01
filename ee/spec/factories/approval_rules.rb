# frozen_string_literal: true

FactoryBot.define do
  factory :approval_merge_request_rule do
    merge_request
    sequence(:name) { |n| "#{ApprovalRuleLike::DEFAULT_NAME}-#{n}" }
  end

  factory :code_owner_rule, parent: :approval_merge_request_rule do
    merge_request
    code_owner true
    sequence(:name) { |n| "*-#{n}.js" }
  end

  factory :approval_project_rule do
    project
    name ApprovalRuleLike::DEFAULT_NAME
  end
end
