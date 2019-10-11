# frozen_string_literal: true

FactoryBot.define do
  factory :path_lock do
    project
    user
    sequence(:path) { |n| "app/model#{n}" }
  end
end
