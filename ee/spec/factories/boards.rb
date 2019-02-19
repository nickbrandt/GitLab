# frozen_string_literal: true

FactoryBot.modify do
  factory :board do
    sequence(:name) { |n| "board#{n}" }
  end
end
