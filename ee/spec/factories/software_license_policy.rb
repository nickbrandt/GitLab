# frozen_string_literal: true

FactoryBot.define do
  factory :software_license_policy, class: SoftwareLicensePolicy do
    approval_status { 1 }
    project
    software_license

    trait :blacklist do
      approval_status { :blacklisted }
    end

    trait :allowed do
      approval_status { :approved }
    end

    trait :denied do
      approval_status { :blacklisted }
    end
  end
end
