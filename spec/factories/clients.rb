# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    name { generate(:name) }
    email { generate(:email) }

    # Associations
    namespace
  end
end
