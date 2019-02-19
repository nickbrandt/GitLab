# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_slack_application_service do
    project
    active true
    type 'GitlabSlackApplicationService'
  end
end
