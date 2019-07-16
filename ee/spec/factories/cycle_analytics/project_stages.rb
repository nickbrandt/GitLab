# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_project_stage, class: CycleAnalytics::ProjectStage do
    sequence(:name) { |n| "Stage ##{n}" }
    hidden { false }
    start_event_identifier { Gitlab::CycleAnalytics::StageEvents::IssueCreated.identifier }
    end_event_identifier { Gitlab::CycleAnalytics::StageEvents::IssueClosed.identifier }
  end
end
