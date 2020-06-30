# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_finding_pipeline, class: 'Vulnerabilities::FindingPipeline' do
    occurrence factory: :vulnerabilities_occurrence
    pipeline factory: :ci_pipeline
  end
end
