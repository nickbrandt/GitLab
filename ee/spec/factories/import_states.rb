# frozen_string_literal: true

FactoryBot.modify do
  factory :import_state do
    trait :mirror do
      transient do
        mirror { true }
        import_url { generate(:url) }
      end

      before(:create) do |import_state, evaluator|
        project = import_state.project
        project.update_columns(mirror: evaluator.mirror,
                               import_url: evaluator.import_url,
                               mirror_user_id: project.creator_id)
      end
    end

    after(:build) do |import_state|
      case import_state.status.to_sym
      when :scheduled
        import_state.last_update_scheduled_at = Time.current
      when :started
        import_state.last_update_started_at = Time.current
      when :finished
        timestamp = Time.current
        import_state.last_update_at = timestamp
        import_state.last_update_started_at = timestamp
      when :failed
        import_state.last_update_at = Time.current
      end
    end

    trait :hard_failed do
      status { :failed }
      retry_count { Gitlab::Mirror::MAX_RETRY + 1 }
      last_update_at { Time.current - 1.minute }
    end
  end
end
