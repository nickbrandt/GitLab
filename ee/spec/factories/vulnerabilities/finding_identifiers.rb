# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_finding_identifier, class: 'Vulnerabilities::FindingIdentifier' do
    occurrence factory: :vulnerabilities_occurrence
    identifier factory: :vulnerabilities_identifier
  end
end
