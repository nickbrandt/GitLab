# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :approver do
    target factory: :merge_request
    user

    after(:create) do |approver, evaluator|
      case approver.target
      when Project
        approver.target.add_developer(approver.user)
      else
        approver.target.project.add_developer(approver.user)
      end
    end
  end
end
