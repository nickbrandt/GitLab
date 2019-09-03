# frozen_string_literal: true

FactoryBot.define do
  factory :software_license, class: SoftwareLicense do
    sequence(:name) { |n| "SOFTWARE-LICENSE-2.7/example_#{n}" }

    trait :mit do
      name { 'MIT' }
    end

    trait :apache_2_0 do
      name { 'Apache 2.0' }
    end
  end
end
