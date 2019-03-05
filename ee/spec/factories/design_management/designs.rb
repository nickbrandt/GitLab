# frozen_string_literal: true

FactoryBot.define do
  factory :design, class: DesignManagement::Design do
    issue
    project { issue.project }
    sequence(:filename) { |n| "homescreen-#{n}.jpg" }
  end
end
