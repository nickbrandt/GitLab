# frozen_string_literal: true

FactoryBot.define do
  factory :geo_node do
    sequence(:url) do |n|
      "http://node#{n}.example.com/gitlab"
    end

    sequence(:name) do |n|
      "node_name_#{n}"
    end

    primary { false }
    sync_object_storage { true }

    trait :primary do
      primary { true }
      minimum_reverification_interval { 7 }
      sync_object_storage { false }
    end

    trait :local_storage_only do
      sync_object_storage { false }
    end
  end
end
