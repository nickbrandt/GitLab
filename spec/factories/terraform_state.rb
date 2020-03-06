# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state do
    project { create(:project) }

    trait :with_file do
      file { fixture_file_upload('spec/fixtures/terraform.tfstate') }
    end
  end
end
