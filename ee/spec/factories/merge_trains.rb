# frozen_string_literal: true

FactoryBot.define do
  factory :merge_train do
    merge_request
    user
    pipeline factory: :ci_pipeline
  end
end
