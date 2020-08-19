# frozen_string_literal: true

FactoryBot.define do
  factory :incident_data, class: 'IncidentManagement::IncidentData' do
    project
    issue { create(:incident, project: project) }
  end
end
