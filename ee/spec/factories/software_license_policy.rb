# frozen_string_literal: true

FactoryBot.define do
  factory :software_license_policy, class: SoftwareLicensePolicy do
    classification { :approved }
    project
    software_license

    trait :allowed do
      classification { :approved }
    end

    trait :denied do
      classification { :denied }
    end
  end
end
