# frozen_string_literal: true

FactoryBot.define do
  factory :software_license_policy, class: SoftwareLicensePolicy do
    classification { :approved }
    project
    software_license

    trait :blacklist do
      classification { :blacklisted }
    end

    trait :allowed do
      classification { :approved }
    end

    trait :denied do
      classification { :blacklisted }
    end
  end
end
