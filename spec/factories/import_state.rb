FactoryBot.define do
  factory :import_state, class: ProjectImportState do
    status :none
    association :project, factory: :project

    transient do
      import_url { generate(:url) }
      import_type nil
    end

    trait :repository do
      association :project, factory: [:project, :repository]
    end

    trait :mirror do
      transient do
        mirror true
        import_url { generate(:url) }
      end

      before(:create) do |import_state, evaluator|
        project = import_state.project
        project.update_columns(mirror: evaluator.mirror,
                               import_url: evaluator.import_url,
                               mirror_user_id: project.creator_id)
      end
    end

    trait :none do
      status :none
    end

    trait :scheduled do
      status :scheduled
      last_update_scheduled_at { Time.now }
    end

    trait :started do
      status :started
      last_update_started_at { Time.now }
    end

    trait :finished do
      timestamp = Time.now

      status :finished
      last_update_at timestamp
      last_successful_update_at timestamp
    end

    trait :failed do
      status :failed
      last_update_at { Time.now }
    end

    trait :hard_failed do
      status :failed
      retry_count { Gitlab::Mirror::MAX_RETRY + 1 }
      last_update_at { Time.now - 1.minute }
    end

    after(:create) do |import_state, evaluator|
      columns = {}
      columns[:import_url] = evaluator.import_url unless evaluator.import_url.blank?
      columns[:import_type] = evaluator.import_type unless evaluator.import_type.blank?

      import_state.project.update_columns(columns)
    end
  end
end
