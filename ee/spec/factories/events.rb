# frozen_string_literal: true

FactoryBot.modify do
  factory :event do
    trait :epic_create_event do
      group
      author(factory: :user)
      target(factory: :epic)
      action { Event::CREATED }
      project { nil }
    end

    trait :for_design do
      transient do
        design { create(:design, issue: create(:issue, project: project)) }
        note { create(:note, author: author, project: project, noteable: design) }
      end

      action { Event::COMMENTED }
      target { note }
    end
  end
end
