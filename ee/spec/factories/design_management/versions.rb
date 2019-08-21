# frozen_string_literal: true

FactoryBot.define do
  factory :design_version, class: DesignManagement::Version do
    sequence(:sha) { |n| Digest::SHA1.hexdigest("commit-like-#{n}") }
    issue { designs.first&.issue || create(:issue) }

    # Warning: this will intentionally result in an invalid version!
    trait :empty do
      transient do
        no_designs true
      end
    end

    after(:build) do |version, evaluator|
      unless evaluator.try(:no_designs) || version.designs.present?
        version.designs << create(:design, issue: version.issue)
      end
    end
  end
end
