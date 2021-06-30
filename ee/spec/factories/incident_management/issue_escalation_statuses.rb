# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_issue_escalation_status, class: 'IncidentManagement::IssueEscalationStatus' do
    association :issue
    triggered

    trait :triggered do
      status { ::IncidentManagement::Escalatable::STATUSES[:triggered] }
    end

    trait :acknowledged do
      status { ::IncidentManagement::Escalatable::STATUSES[:acknowledged] }
    end

    trait :resolved do
      status { ::IncidentManagement::Escalatable::STATUSES[:resolved] }
      resolved_at { Time.current }
    end

    trait :ignored do
      status { ::IncidentManagement::Escalatable::STATUSES[:ignored] }
    end
  end
end
