# frozen_string_literal: true

FactoryBot.define do
  sequence(:sequential_date) do |n|
    n.days.from_now
  end

  factory :sprint do
    title
    start_date { generate(:sequential_date) }
    due_date { generate(:sequential_date) }

    transient do
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    trait :upcoming do
      state_id { Sprint::STATE_ID_MAP[:upcoming] }
    end

    trait :in_progress do
      state_id { Sprint::STATE_ID_MAP[:in_progress] }
    end

    trait :closed do
      state_id { Sprint::STATE_ID_MAP[:closed] }
    end

    trait(:skip_future_date_validation) do
      after(:stub, :build) do |sprint|
        sprint.skip_future_date_validation = true
      end
    end

    after(:build, :stub) do |sprint, evaluator|
      if evaluator.group
        sprint.group = evaluator.group
      elsif evaluator.group_id
        sprint.group_id = evaluator.group_id
      elsif evaluator.project
        sprint.project = evaluator.project
      elsif evaluator.project_id
        sprint.project_id = evaluator.project_id
      elsif evaluator.resource_parent
        id = evaluator.resource_parent.id
        evaluator.resource_parent.is_a?(Group) ? evaluator.group_id = id : evaluator.project_id = id
      else
        sprint.project = create(:project)
      end
    end

    factory :upcoming_sprint, traits: [:upcoming]
    factory :in_progress_sprint, traits: [:in_progress]
    factory :closed_sprint, traits: [:closed]
  end
end
