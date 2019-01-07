# frozen_string_literal: true

FactoryBot.define do
  factory :approval_merge_request_rule do
    merge_request
    name ApprovalRuleLike::DEFAULT_NAME
  end

  factory :approval_project_rule do
    project
    name ApprovalRuleLike::DEFAULT_NAME
  end
end
