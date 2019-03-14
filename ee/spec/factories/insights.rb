# frozen_string_literal: true

FactoryBot.define do
  factory :insights_issuables, class: Hash do
    initialize_with do
      {
        Manage: 1,
        Plan: 3,
        Create: 2,
        undefined: 1
      }.with_indifferent_access
    end
  end

  factory :insights_issuables_per_month, class: Hash do
    initialize_with do
      {
        'January 2019' => {
          Manage: 1,
          Plan: 1,
          Create: 1,
          undefined: 0
        }.with_indifferent_access,
        'February 2019' => {
          Manage: 0,
          Plan: 1,
          Create: 0,
          undefined: 0
        }.with_indifferent_access,
        'March 2019' => {
          Manage: 0,
          Plan: 1,
          Create: 1,
          undefined: 1
        }.with_indifferent_access
      }
    end
  end
end
