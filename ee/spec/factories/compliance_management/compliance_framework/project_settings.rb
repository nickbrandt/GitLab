# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_framework_project_setting, class: 'ComplianceManagement::ComplianceFramework::ProjectSettings' do
    project
    framework { ComplianceManagement::ComplianceFramework::ProjectSettings.frameworks.keys.sample }

    trait :sox do
      framework { 'sox' }
    end
  end
end
