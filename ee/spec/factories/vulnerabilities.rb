# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability do
    project
    author
    title { generate(:title) }
    title_html { "<h2>#{title}</h2>" }
    severity { :high }
    confidence { :medium }

    trait :opened do
      state { :opened }
    end

    trait :closed do
      state { :closed }
      closed_at { Time.now }
    end
  end
end
