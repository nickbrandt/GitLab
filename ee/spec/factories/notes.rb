# frozen_string_literal: true

FactoryBot.modify do
  factory :note do
    trait :on_epic do
      noteable { association(:epic) }
      project { nil }
    end

    trait :on_vulnerability do
      noteable { association(:vulnerability, project: project) }
    end

    trait :on_design do
      transient do
        issue { association(:issue, project: project) }
      end
      noteable { association(:design, :with_file, issue: issue) }

      after(:build) do |note|
        next if note.project == note.noteable.project

        # note validations require consistency between these two objects
        note.project = note.noteable.project
      end
    end

    trait :with_review do
      review
    end
  end
end

FactoryBot.define do
  factory :note_on_epic, parent: :note, traits: [:on_epic]
  factory :note_on_vulnerability, parent: :note, traits: [:on_vulnerability]

  factory :discussion_note_on_vulnerability, parent: :note, traits: [:on_vulnerability], class: 'DiscussionNote'

  factory :diff_note_on_design, parent: :note, traits: [:on_design], class: 'DiffNote' do
    position { build(:image_diff_position, file: noteable.full_path, diff_refs: noteable.diff_refs) }
  end
end
