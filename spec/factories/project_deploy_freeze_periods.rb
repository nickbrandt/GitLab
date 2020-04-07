# frozen_string_literal: true

FactoryBot.define do
  factory :project_deploy_freeze_period do
    project
    freeze_start { '0 23 * * 5' }
    freeze_end { '0 7 * * 1' }
    timezone { 'UTC' }
  end
end
