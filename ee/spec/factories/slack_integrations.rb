# frozen_string_literal: true

FactoryBot.define do
  factory :slack_integration do
    sequence(:team_id) { |n| "T123#{n}" }
    sequence(:user_id) { |n| "U123#{n}" }
    sequence(:team_name) { |n| "team#{n}" }
    sequence(:alias) { |n| "namespace#{n}/project_name#{n}" }

    integration factory: :gitlab_slack_application_integration
  end
end
