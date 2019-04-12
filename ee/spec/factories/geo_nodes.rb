FactoryBot.define do
  factory :geo_node do
    sequence(:url) do |n|
      "http://node#{n}.example.com/gitlab"
    end

    sequence(:name) do |n|
      "node_name_#{n}"
    end

    primary false

    trait :primary do
      primary true
      minimum_reverification_interval 7
    end
  end
end
