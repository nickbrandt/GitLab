# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_statistic, class: 'Vulnerabilities::Statistic' do
    project

    trait :a do
      info { 1 }
    end

    trait :b do
      low { 1 }
    end

    trait :c do
      medium { 1 }
    end

    trait :d do
      high { 1 }
      unknown { 1 }
    end

    trait :f do
      critical { 1 }
    end
  end
end
