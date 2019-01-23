# frozen_string_literal: true

FactoryBot.modify do
  factory :note do
    trait :on_epic do
      noteable { create(:epic) }
      project nil
    end
  end
end

FactoryBot.define do
  factory :note_on_epic, parent: :note, traits: [:on_epic]
end
