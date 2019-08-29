# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_slack_application_service do
    project
    active { true }
    type { 'GitlabSlackApplicationService' }
  end

  factory :alerts_service do
    project
    type { 'AlertsService' }
    active { true }

    trait :inactive do
      active { false }
    end
  end

  factory :github_service do
    project
    active { true }
    token { 'github-token' }
    type { 'GithubService' }
  end
end
