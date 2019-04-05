# frozen_string_literal: true

FactoryBot.define do
  factory :design_version, class: DesignManagement::Version do
    sequence(:sha) { |n| Digest::SHA1.hexdigest("commit-like-#{n}") }
  end
end
